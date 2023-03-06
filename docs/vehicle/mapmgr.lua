-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local graphpath = require('graphpath')
local pointBBox = require('quadtree').pointBBox
local kdTreeBox2D = require('kdtreebox2d')

local stringFind, stringSub, stringFormat, max, min = string.find, string.sub, string.format, math.max, math.min
local vecUp = vec3(0, 0, 1)
local vecY = vec3(0, 1, 0)
local vecX = vec3(1, 0, 0)

local M = {}

M.objects = {}
M.objectCollisionIds = {}

local serTmp = {}
local mapData, mapBuildSerial, edgeKdTree, maxRadius
local lastSimTime = -1

local function setMap(newbuildSerial)
  if newbuildSerial and newbuildSerial == mapBuildSerial then return end
  mapBuildSerial = newbuildSerial

  local _map = lpack.decode(obj:getLastMailbox('mapData'))
  if not (_map and _map.graphData and _map.edgeKdTree and _map.maxRadius and _map.nodeAliases) then return end

  maxRadius = _map.maxRadius
  M.nodeAliases = _map.nodeAliases

  mapData = graphpath.newGraphpath()
  mapData:import(_map.graphData)
  M.mapData = mapData

  edgeKdTree = kdTreeBox2D.new()
  edgeKdTree:import(_map.edgeKdTree)

  M.rules = _map.rules

  obj:queueGameEngineLua("extensions.hook('onVehicleMapmgrUpdate', "..tostring(objectId)..")")
end

local function updateDrivabilities(changeSet)
  -- changeSet format: {nodeA1, nodeB1, driv1, nodeA2, nodeB2, driv2, ...}

  if not (mapData and mapData.graph) then
    return
  end

  local _changeSet = lpack.decode(changeSet)
  local graph = mapData.graph

  for i = 1, #_changeSet, 3 do
    -- on veh side each direction of a graphpath edge has it own copy of the data table (the two should be identical)
    -- this is due to serialization not preserving references.
    local edge = graph[_changeSet[i]][_changeSet[i+1]]
    local currentDrivability = max(1e-30, edge.drivability)
    local newDrivability = max(1e-30, _changeSet[i+2])
    edge.len = edge.len * currentDrivability / newDrivability -- edge apparent length
    edge.drivability = newDrivability
    graph[_changeSet[i+1]][_changeSet[i]].len = edge.len
    graph[_changeSet[i+1]][_changeSet[i]].drivability = newDrivability
    _changeSet[i+2] = newDrivability - currentDrivability -- keep track of whether an edge had its drivability reduced or increased
  end

  M.changeSet = _changeSet
end

local function requestMap()
  obj:queueGameEngineLua(string.format('map.request(%q, %q)', tostring(objectId), tostring(mapBuildSerial)))
end

local function setSignals(data)
  M.signalsData = deserialize(data)
end

local function updateSignal(node, idx, action)
  if not M.signalsData or not node or not idx or not M.signalsData.nodes[node] then return end
  M.signalsData.nodes[node][idx].action = tonumber(action) or 1
end

local states = {}
M.sendTracking = nop
local function sendTracking()
  local objCols = M.objectCollisionIds
  table.clear(objCols)
  obj:getObjectCollisionIds(objCols)

  local anyPlayerSeated = tostring(playerInfo.anyPlayerSeated)
  local objColsCount = #objCols

  if electrics.values.horn ~= 0 then states.horn = electrics.values.horn end
  if electrics.values.lightbar ~= 0 and electrics.values.lightbar ~= 1 then states.lightbar = electrics.values.lightbar end
  if objColsCount > 0 then
    for i = 1, objColsCount do
      serTmp[i] = stringFormat('[%s]=1', objCols[i])
    end
    obj:queueGameEngineLua(stringFormat('map.objectData(%s,%s,%s,%s,{%s})', objectId, anyPlayerSeated, math.floor(beamstate.damage), next(states) and serialize(states) or 'nil', table.concat(serTmp, ',')))
    table.clear(serTmp)
  else
    obj:queueGameEngineLua(stringFormat('map.objectData(%s,%s,%s,%s)', objectId, anyPlayerSeated, math.floor(beamstate.damage), next(states) and serialize(states) or 'nil'))
  end
  table.clear(states)
end

local function enableTracking(name)
  obj:queueGameEngineLua(stringFormat('map.setNameForId(%s, %s)', name and '"'..name..'"' or objectId, objectId))
  M.sendTracking = sendTracking
end

local function disableTracking(forceDisable)
  if forceDisable or not playerInfo.anyPlayerSeated then
    M.sendTracking = nop
  end
end

-- the same function is also located in ge/map.lua
local function findClosestRoad(position)
  --log('A','mapmgr', 'findClosestRoad called with '..position.x..','..position.y..','..position.z)
  local nodePositions = mapData.positions
  local bestRoad1, bestRoad2, bestDist
  local searchRadius = maxRadius
  repeat
    local searchRadiusSq = searchRadius * searchRadius
    local minCurDist = searchRadiusSq * 4
    bestDist = searchRadiusSq
    for item_id in edgeKdTree:queryNotNested(pointBBox(position.x, position.y, searchRadius)) do
      local i = stringFind(item_id, '\0')
      local n1id = stringSub(item_id, 1, i-1)
      local n2id = stringSub(item_id, i+1, #item_id)
      local curDist = position:squaredDistanceToLineSegment(nodePositions[n1id], nodePositions[n2id])
      if curDist <= bestDist then
        bestDist = curDist
        bestRoad1 = n1id
        bestRoad2 = n2id
      else
        minCurDist = min(minCurDist, curDist) -- this is the smallest curDist that is larger than bestDist
      end
    end

    searchRadius = math.sqrt(max(minCurDist, searchRadiusSq * 4))
  until bestRoad1 or searchRadius > 200

  return bestRoad1, bestRoad2, math.sqrt(bestDist)
end

local function startPosLinks(position, wZ)
  wZ = wZ or 1 -- zbias
  local nodePositions = mapData.positions
  local nodeRadius = mapData.radius
  local costs = table.new(0, 32)
  local xnorms = table.new(0, 32)
  local seenEdges = table.new(0, 32)
  local j, names = 0, table.new(32, 0)
  local searchRadius = maxRadius * 5
  local tmpVec = vec3()
  local edgeVec = vec3()

  return function ()
    repeat
      if j > 0 then
        local name = names[j]
        names[j] = nil
        j = j - 1
        return name, costs[name], xnorms[name]
      else
        for item_id in edgeKdTree:queryNotNested(pointBBox(position.x, position.y, searchRadius)) do
          if not seenEdges[item_id] then
            seenEdges[item_id] = true
            local i = stringFind(item_id, '\0')
            local n1id = stringSub(item_id, 1, i-1)
            local n2id = stringSub(item_id, i+1, #item_id)
            local n1Pos = nodePositions[n1id]
            edgeVec:set(nodePositions[n2id])
            edgeVec:setSub(n1Pos)
            tmpVec:set(position)
            tmpVec:setSub(n1Pos) -- node1ToPosVec
            local xnorm = min(1, max(0, edgeVec:dot(tmpVec) / (edgeVec:squaredLength() + 1e-30)))
            local key
            if xnorm == 0 then
              key = n1id
            elseif xnorm == 1 then
              key = n2id
            else
              key = {n1id, n2id}
              xnorms[key] = xnorm -- we only need to store the xnorm if 1 < xnorm < 0
            end
            if not costs[key] then
              edgeVec:setScaled(xnorm)
              tmpVec:setSub(edgeVec) -- distVec
              tmpVec:setScaled(max(0, 1 - max(nodeRadius[n1id], nodeRadius[n2id]) / (tmpVec:length() + 1e-30)))
              costs[key] = square(square(tmpVec.x) + square(tmpVec.y) + square(wZ * tmpVec.z))
              j = j + 1
              names[j] = key
            end
          end
        end

        table.sort(names, function(n1, n2) return costs[n1] > costs[n2] end)

        searchRadius = searchRadius * 2
      end
    until searchRadius > 2000

    return nil, nil, nil
  end
end

local function getPointToPointPath(startPos, targetPos, cutOffDrivability, dirMult, penaltyAboveCutoff, penaltyBelowCutoff, wZ)
  -- startPos: path source position
  -- targetPos: target position (vec3)
  -- cutOffDrivability: penalize roads with drivability <= cutOffDrivability
  -- dirMult: amount of penalty to impose to path if it does not respect road legal directions (should be larger than 1 typically >= 10e4).
  --          If equal to nil or 1 then it means no penalty.
  -- penaltyAboveCutoff: penalty multiplier for roads above the drivability cutoff
  -- penaltyBelowCutoff: penalty multiplier for roads below the drivability cutoff
  -- wZ: number (typically >= 1). When higher than 1 destination node of optimum path will be biased towards minimizing height difference to targetPos.

  if mapData == nil or edgeKdTree == nil then return {} end
  wZ = wZ or 4
  local iter = startPosLinks(startPos, wZ)
  return mapData:getPointToPointPath(startPos, iter, targetPos, cutOffDrivability, dirMult, penaltyAboveCutoff, penaltyBelowCutoff, wZ)
end

local function reset()
  M.objects = {}
end

local function init()
  if wheels.wheelCount > 0 or (v.data.general and v.data.general.enableTracking) then
    enableTracking()
  end
end

local function objectData(objectsData)
  M.objects = objectsData
end

local function getObjects()
  local simTime = obj:getSimTime()
  if simTime ~= lastSimTime then
    local objData = obj:getLastMailbox("objUpdate")
    M.objects = objData == "" and {} or lpack.decode(objData)
    lastSimTime = simTime
  end
  return M.objects
end

local function surfaceNormalBelow(p, r)
  --   p3
  --     \
  --      \ r
  --       \     r
  --        p - - - - p1     | - > y
  --       /                 v
  --      / r                x
  --     /
  --   p2

  r = r or 2
  local hr = 1.2 * r -- controls inclination angle up to (at least) which result is correct (arctan(1.2) ~ 50deg)

  local p1 = hr * vecUp;
  p1:setAdd(p)
  p1.y = p1.y + r

  local p2 = (-1.5 * r) * vecY -- -(1 + cos(60)) * r
  p2:setAdd(p1)
  local p3 = vec3(p2)
  p2.x = p2.x + 0.8660254037844386 * r -- sin(60) * r
  p3.x = p3.x - 0.8660254037844386 * r

  p1.z = obj:getSurfaceHeightBelow(p1)
  p2.z = obj:getSurfaceHeightBelow(p2)
  p3.z = obj:getSurfaceHeightBelow(p3)

  -- in what follows p3 becomes the normal vector
  if min(p1.z, p2.z, p3.z) < p.z - hr then
    p3:set(vecUp)
  else
    p2:setSub(p3)
    p1:setSub(p3)
    p3:set(p2.y * p1.z - p2.z * p1.y, p2.z * p1.x - p2.x * p1.z, p2.x * p1.y - p2.y * p1.x) -- p2 x p1
    p3:normalize()
  end

  return p3
end

M.findClosestRoad = findClosestRoad
M.objectData = objectData
M.init = init
M.reset = reset
M.requestMap = requestMap
M.setMap = setMap
M.setSignals = setSignals
M.updateSignal = updateSignal
M.enableTracking = enableTracking
M.disableTracking = disableTracking
M.surfaceNormalBelow = surfaceNormalBelow
M.getPointToPointPath = getPointToPointPath
M.updateDrivabilities = updateDrivabilities
M.getObjects = getObjects

return M
