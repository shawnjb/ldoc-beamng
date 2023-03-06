-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max = math.max
local min = math.min
local abs = math.abs

local huge = math.huge

-- these are defined in C, do not change the values
local NORMALTYPE = 0
local BEAM_ANISOTROPIC = 1
local BEAM_BOUNDED = 2
local BEAM_PRESSURED = 3
local BEAM_LBEAM = 4
local BEAM_BROKEN = 5
local BEAM_HYDRO = 6
local BEAM_SUPPORT = 7

local beamTypesNames = {
  [NORMALTYPE] = "NORMALTYPE",
  [BEAM_ANISOTROPIC] = "BEAM_ANISOTROPIC",
  [BEAM_BOUNDED] = "BEAM_BOUNDED",
  [BEAM_PRESSURED] = "BEAM_PRESSURED",
  [BEAM_LBEAM] = "BEAM_LBEAM",
  [BEAM_BROKEN] = "BEAM_BROKEN",
  [BEAM_HYDRO] = "BEAM_HYDRO",
  [BEAM_SUPPORT] = "BEAM_SUPPORT",
}

local beamTypesColors = {
  [NORMALTYPE] = color(0, 223, 0, 255),
  [BEAM_HYDRO] = color(0, 100, 255, 255),
  [BEAM_ANISOTROPIC] = color(255, 135, 63, 255),
  [BEAM_BOUNDED] = color(255, 255, 0, 255),
  [BEAM_LBEAM] = color(92, 92, 92, 255),
  [BEAM_SUPPORT] = color(223, 0, 223, 255),
  [BEAM_PRESSURED] = color(0, 255, 255, 255),
  [BEAM_BROKEN] = color(255, 0, 0, 255),
}

M.initState = {
  physicsEnabled = true,
  vehicleDebugVisible = false,
  vehicle = {
    nodeTextMode = 1,
    nodeTextModes = {
      {name = "off"},
      {name = "names"},
      {name = "numbers"},
      {name = "names+numbers"},
      {name = "weights"},
      {name = "materials"}
    },
    nodeVisMode = 1,
    nodeVisModes = {
      {name = "off"},
      {name = "simple", nodeScale = 0.015},
      {name = "weights", nodeScale = 1},
      {name = "displacement", nodeScale = 0.02},
      {name = "velocities", nodeScale = 0.02},
      {name = "forces", nodeScale = 0.01},
      {name = "density", nodeScale = 0.02}
    },
    nodeVisWidthScale = 1,
    nodeVisAlpha = 1,
    beamVisMode = 1,
    beamVisModes = {
      {name = "off"},
      {name = "simple", beamScale = 0.002},
      {name = "type", beamScale = 0.002},
      {name = "type + broken", beamScale = 0.002},
      {name = "broken only", beamScale = 0.002},
      {name = "oldStress", beamScale = 0.002},
      {name = "stress", beamScale = 0.002, usesRange = true, rangeMinCap = 0, rangeMaxCap = 100000, rangeMin = 0, rangeMax = 10000},
      {name = "displacement", beamScale = 0.002, usesRange = true, rangeMinCap = 0, rangeMaxCap = 10, rangeMin = 0, rangeMax = 0.1},
      {name = "deformation", beamScale = 0.002, usesRange = true, rangeMinCap = 0.0, rangeMaxCap = 10.0, rangeMin = 0.0, rangeMax = 2.0},
      {name = "breakgroups", beamScale = 0.002},
      {name = "deformgroups", beamScale = 0.002},
      {name = "beamDamp", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamDampFast", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamDampRebound", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamDampReboundFast", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamDampVelocitySplit", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamDeform", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamLimitDamp", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamLimitDampRebound", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamLongBound", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamPrecompression", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamPrecompressionRange", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamPrecompressionTime", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamShortBound", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamSpring", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "beamStrength", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "boundZone", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "dampCutoffHz", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "dampExpansion", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "deformLimit", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "deformLimitExpansion", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "deformationTriggerRatio", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "longBoundRange", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "precompressionRange", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "shortBoundRange", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
      {name = "springExpansion", beamScale = 0.002, usesRange = true, autoRange = true, showInfinity = true},
    },
    beamVisWidthScale = 1,
    beamVisAlpha = 1,
    collisionTriangle = false,
    aeroMode = 1,
    aeroModes = {
      {name = "off"},
      {name = "drag+lift"},
      {name = "aoa"},
      {name = "combined"}
    },
    aerodynamicsScale = 0.1,
    tireContactPoint = false,
    cogMode = 1,
    cogModes = {
      {name = "off"},
      {name = "on"},
      {name = "nowheels"}
    }
  }
}

local nodeDisplayDistance = 0 -- broken atm since it uses the center point of the camera :\
local wheelContacts = {}

local nodesCount = 0
local beamsCount = 0

local requestDrawnNodesCallbacks
local requestDrawnBeamsCallbacks

local function selectNode()

end

local function nodeCollision(p)
  if not M.state.vehicle.tireContactPoint then
    M.nodeCollision = nop
    return
  end
  local wheelId = v.data.nodes[p.id1].wheelID
  if wheelId then
    wheelContacts = wheelContacts or {}
    if not wheelContacts[wheelId] then
      wheelContacts[wheelId] = {totalForce = 0, contactPoint = vec3(0, 0, 0)}
    end
    local wheelC = wheelContacts[wheelId]
    wheelC.totalForce = wheelC.totalForce + p.normalForce
    wheelC.contactPoint = wheelC.contactPoint + vec3(p.pos) * p.normalForce
  end
end

local function beamBroke(id, energy)
  local beam = v.data.beams[id]
  log("I", "bdebug.beamBroken", string.format("beam %d broke: %s [%d]  ->  %s [%d]", id, (v.data.nodes[beam.id1].name or "unnamed"), beam.id1, (v.data.nodes[beam.id2].name or "unnamed"), beam.id2))
  guihooks.message({txt = "vehicle.beamstate.beamBroke", context = {id = id, id1 = beam.id1, id2 = beam.id2, id1name = v.data.nodes[beam.id1].name, id2name = v.data.nodes[beam.id2].name}})
end

local function beamDeformed(id, ratio)
  local beam = v.data.beams[id]
  -- "deformgroups"
  if M.state.vehicle.beamVisMode == 10 and beam.deformGroup then
    log("I", "bdebug.beamDeformed", string.format("deformgroup triggered: %s beam %d, %s [%d]  ->  %s [%d]", beam.deformGroup, id, (v.data.nodes[beam.id1].name or "unnamed"), beam.id1, (v.data.nodes[beam.id2].name or "unnamed"), beam.id2))
  else
    log("I", "bdebug.beamDeformed", string.format("beam %d deformed: %s [%d]  ->  %s [%d]", id, (v.data.nodes[beam.id1].name or "unnamed"), beam.id1, (v.data.nodes[beam.id2].name or "unnamed"), beam.id2))
  end
end

local function debugDrawNode(col, node, txt)
  if node.name == nil then
    obj.debugDrawProxy:drawNodeText(node.cid, col, "[" .. tostring(node.cid) .. "] " .. txt, nodeDisplayDistance)
  else
    obj.debugDrawProxy:drawNodeText(node.cid, col, tostring(node.name) .. " " .. txt, nodeDisplayDistance)
  end
end

local function visualizeWheelThermals()
  if M.state.vehicle.wheelThermals then
    local baseTemp = obj:getEnvTemperature() - 10

    for _, wd in pairs(wheels.wheels) do
      local pressureGroupID = v.data.pressureGroups[wd.pressureGroup]

      if pressureGroupID then
        local wheelAvgTemp = obj:getWheelAvgTemperature(wd.wheelID)
        local wheelCoreTemp = obj:getWheelCoreTemperature(wd.wheelID)

        local wheelAirPressure = obj:getGroupPressure(pressureGroupID)
        obj.debugDrawProxy:drawNodeSphere(wd.node1, 0.04, ironbowColor((wheelCoreTemp - baseTemp) * 0.004))
        obj.debugDrawProxy:drawNodeSphere(wd.node2, 0.04, ironbowColor((wheelCoreTemp - baseTemp) * 0.004))
        obj.debugDrawProxy:drawNodeText(wd.node1, ironbowColor((wheelCoreTemp - baseTemp) * 0.004), string.format("%s%.1f %s%.1f %s%.1f", "tT:", wheelAvgTemp - 273.15, "tC:", wheelCoreTemp - 273.15, "psi:", wheelAirPressure*0.000145038-14.5), 0)

        --local wheelAvgTemp = obj:getwheelCoreTemperature(wd.wheelID)

        for _, nid in pairs(wd.treadNodes or {}) do
          obj.debugDrawProxy:drawNodeSphere(nid, 0.02, ironbowColor((obj:getNodeTemperature(nid) - baseTemp) * 0.004))
        end
        for _, nid in pairs(wd.nodes or {}) do
          obj.debugDrawProxy:drawNodeSphere(nid, 0.02, ironbowColor((obj:getNodeTemperature(nid) - baseTemp) * 0.004))
        end
      end
    end
  end
end

local function visualizeTireContactPoint()
  if M.state.vehicle.tireContactPoint and wheelContacts then
    M.nodeCollision = nodeCollision
    for _, c in pairs(wheelContacts) do
      obj.debugDrawProxy:drawSphere(0.02, (c.contactPoint / c.totalForce), color(255, 0, 0, 255))
    end
    table.clear(wheelContacts)
  end
end

local function visualizeCollisionTriangles()
  if M.state.vehicle.collisionTriangle then
    obj.debugDrawProxy:drawColTris(0, color(0, 0, 0, 150), color(0, 255, 0, 50), color(255, 0, 255, 50), 1)
  end
end

local function visualizeAerodynamics()
  local modeID = M.state.vehicle.aeroMode

  -- "off"
  if modeID == 1 then return end

  -- "drag+lift"
  if modeID == 2 then
    obj.debugDrawProxy:drawAerodynamicsCenterOfPressure(color(255, 0, 0, 255), color(55, 55, 255, 255), color(255, 255, 0, 255), color(0, 0, 0, 0), color(0, 0, 0, 0), M.state.vehicle.aerodynamicsScale)

    -- "aoa"
  elseif modeID == 3 then
    obj.debugDrawProxy:drawAerodynamicsCenterOfPressure(color(255, 0, 0, 0), color(55, 55, 255, 0), color(255, 255, 0, 0), color(0, 0, 0, 255), color(0, 0, 0, 0), M.state.vehicle.aerodynamicsScale)

  -- "combined"
  elseif modeID == 4 then
    obj.debugDrawProxy:drawAerodynamicsCenterOfPressure(color(255, 0, 0, 255), color(55, 55, 255, 255), color(255, 255, 0, 255), color(0, 0, 0, 255), color(0, 0, 0, 0), M.state.vehicle.aerodynamicsScale)
  end
end

local function visualizeCOG()
  local modeID = M.state.vehicle.cogMode

  -- "off"
  if not modeID or modeID == 1 then return end

  -- not "off"
  if modeID > 1 then
    local p = obj:calcCenterOfGravity(modeID == 3)
    obj.debugDrawProxy:drawAerodynamicsCenterOfPressure(color(0, 0, 0, 0), color(0, 0, 0, 0), color(0, 0, 0, 0), color(0, 0, 0, 0), color(0, 0, 255, 255), 0.1)
    obj.debugDrawProxy:drawSphere(0.1, p, color(255, 0, 0, 255))
    obj.debugDrawProxy:drawText(p + vec3(0, 0, 0.3), color(255, 0, 0, 255), "COG")

    if playerInfo.firstPlayerSeated then
      obj.debugDrawProxy:drawText2D(vec3(40, 100, 0), color(0, 0, 0, 255), "COG distance above ground: " .. string.format("%0.3f m", obj:getDistanceFromTerrainPoint(p)))
    end
  end
end

function visualizeNodesTexts()
  local modeID = M.state.vehicle.nodeTextMode

  -- "off"
  if modeID == 1 then return end

  -- "names"
  if modeID == 2 then
    local col = color(255, 0, 255, 255)
    for i = 0, nodesCount - 1 do
      local node = v.data.nodes[i]
      debugDrawNode(col, node, "")
    end

  -- "numbers
  elseif modeID == 3 then
    obj.debugDrawProxy:drawNodeNumbers(color(0, 128, 255, 255), nodeDisplayDistance)

  -- "names+numbers"
  elseif modeID == 4 then
    local col = color(128, 0, 255, 255)
    for i = 0, nodesCount - 1 do
      local node = v.data.nodes[i]
      debugDrawNode(col, node, "" .. node.cid)
    end

  -- "weights"
  elseif modeID == 5 then
    local totalWeight = 0
    for i = 0, nodesCount - 1 do
      local node = v.data.nodes[i]
      local nodeWeight = obj:getNodeMass(node.cid)
      totalWeight = totalWeight + nodeWeight
      local txt = string.format("%.2fkg", nodeWeight)
      obj.debugDrawProxy:drawNodeText(node.cid, color(255 - (nodeWeight * 20), 0, 0, 255), txt, nodeDisplayDistance)
    end
    if playerInfo.firstPlayerSeated then
      obj.debugDrawProxy:drawText2D(vec3(40, 100, 0), color(0, 0, 0, 255), "Total weight: " .. string.format("%.2f kg", totalWeight))
    end

  -- "materials"
  elseif modeID == 6 then
    local materials = particles.getMaterialsParticlesTable()
    for i = 0, nodesCount - 1 do
      local node = v.data.nodes[i]
      local mat = materials[node.nodeMaterial]
      local matname = "unknown"
      local col = color(255, 0, 0, 255) -- unknown material: red
      if mat ~= nil then
        col = color(mat.colorR, mat.colorG, mat.colorB, 255)
        matname = mat.name
      end
      debugDrawNode(col, node, matname)
    end
  end
end

local nodeForceAvg = 1
local nodesDrawn
local function visualizeNodes()
  local dirty = false

  local modeID = M.state.vehicle.nodeVisMode
  local mode = M.state.vehicle.nodeVisModes[modeID]
  if not mode then return false end

  local rangeMin = mode.rangeMin or -huge
  local rangeMax = mode.rangeMax or huge

  local minVal = huge
  local maxVal = -huge
  local nodeScale = (mode.nodeScale or 0.015) * M.state.vehicle.nodeVisWidthScale
  local alpha = M.state.vehicle.nodeVisAlpha

  nodesDrawn = nodesDrawn or {}
  table.clear(nodesDrawn)
  local ndi = 1

  -- "off"
  if modeID == 1 then return dirty end

  -- highlighted nodes
  for i = 0, nodesCount - 1 do
    local node = v.data.nodes[i]
    if node.highlight then
      obj.debugDrawProxy:drawNodeSphere(node.cid, node.highlight.radius, parseColor(node.highlight.col))
    end
  end

  -- "simple"
  if modeID == 2 then
    for i = 0, nodesCount - 1 do
      local node = v.data.nodes[i]
      local c
      if node.fixed then
        c = color(255, 0, 255, 200 * alpha)
      elseif node.selfCollision then
        c = color(255, 255, 0, 200 * alpha)
      elseif node.collision == false then
        c = color(255, 0, 212, 200 * alpha)
      else
        c = color(0, 255, 255, 200 * alpha)
      end
      obj.debugDrawProxy:drawNodeSphere(node.cid, nodeScale, c)

      nodesDrawn[ndi] = node.cid
      ndi = ndi + 1
    end

  -- "weights"
  elseif modeID == 3 then
    local totalWeight, _, _ = extensions.vehicleEditor_nodes.calculateNodesWeight()

    local avgNodeScale = 0

    for i = 0, nodesCount - 1 do
      local node = v.data.nodes[i]
      local c
      if node.fixed then
        c = color(255, 0, 255, 200 * alpha)
      elseif node.selfCollision then
        c = color(255, 255, 0, 200 * alpha)
      elseif node.collision == false then
        c = color(255, 0, 212, 200 * alpha)
      else
        c = color(0, 255, 255, 200 * alpha)
      end

      local nodeMass = obj:getNodeMass(node.cid)

      local r = (obj:getNodeMass(node.cid) / (totalWeight / nodesCount)) ^ 0.4 * 0.05
      if nodeMass >= rangeMin and nodeMass <= rangeMax then
        local newNodeScale = r * nodeScale
        obj.debugDrawProxy:drawNodeSphere(node.cid, newNodeScale, c)
        avgNodeScale = avgNodeScale + newNodeScale

        nodesDrawn[ndi] = node.cid
        ndi = ndi + 1
      end
    end

    nodeScale = ndi >= 2 and avgNodeScale / (ndi - 1) or nodeScale

  -- "displacement"
  elseif modeID == 4 then
    for i = 0, nodesCount - 1 do
      local node = v.data.nodes[i]
      local displacementVec = obj:getNodePositionRelative(node.cid)
      displacementVec:setSub(obj:getOriginalNodePositionRelative(node.cid))
      local displacement = displacementVec:length() * 10

      local a = min(1, displacement) * 255 * alpha
      if a > 5 then
        local r = min(1, displacement) * 255
        obj.debugDrawProxy:drawNodeSphere(node.cid, nodeScale, color(r, 0, 0, a))

        nodesDrawn[ndi] = node.cid
        ndi = ndi + 1
      end
    end

  -- "velocities"
  elseif modeID == 5 then
    local vecVel = obj:getVelocity()
    for i = 0, nodesCount - 1 do
      local node = v.data.nodes[i]
      local vel = obj:getNodeVelocityVector(node.cid) - vecVel
      local speed = vel:length()

      if speed >= rangeMin and speed <= rangeMax then
        local c = min(255, speed * 10)
        local col = color(c, 0, 0, (c + 60) * alpha)

        obj.debugDrawProxy:drawNodeSphere(node.cid, nodeScale, col)
        obj.debugDrawProxy:drawNodeVector(node.cid, (vel * 0.3), col)

        nodesDrawn[ndi] = node.cid
        ndi = ndi + 1
      end
    end

  -- "forces"
  elseif modeID == 6 then
    local newAvg = 0
    local invAvgNodeForce = 1 / nodeForceAvg
    local nodesCount = nodesCount

    for i = 0, nodesCount - 1 do
      local node = v.data.nodes[i]
      local frc = obj:getNodeForceVector(node.cid)
      local frc_length = frc:length()

      newAvg = newAvg + frc_length
      if frc_length >= rangeMin and frc_length <= rangeMax then
        local c = min(255, (frc_length * invAvgNodeForce) * 255)
        local col = color(c, 0, 0, (c + 100) * alpha)
        obj.debugDrawProxy:drawNodeSphere(node.cid, nodeScale, col)
        obj.debugDrawProxy:drawNodeVector3d(nodeScale, node.cid, (frc * invAvgNodeForce), col)

        nodesDrawn[ndi] = node.cid
        ndi = ndi + 1
      end
    end
    nodeForceAvg = (newAvg / (nodesCount + 1 + 1e-30)) * 10 + 300

  -- "density"
  elseif modeID == 7 then
    local col
    local colorWater = color(255, 0, 0, 200 * alpha)
    local colorAir = color(0, 200, 0, 200 * alpha)
    for i = 0, nodesCount - 1 do
      local node = v.data.nodes[i]
      local inWater = obj:inWater(node.cid)
      if inWater then
        col = colorWater
      else
        col = colorAir
      end
      obj.debugDrawProxy:drawNodeSphere(node.cid, nodeScale, col)

      nodesDrawn[ndi] = node.cid
      ndi = ndi + 1
    end
  end

  -- If auto range enabled and at least one beam value exists, use it to calculate range min/max values
  if mode.autoRange and minVal ~= huge and maxVal ~= -huge then
    if not mode.rangeMinCap or (mode.rangeMinCap and minVal < mode.rangeMinCap) then
      mode.rangeMinCap = minVal
      dirty = true
    end

    if not mode.rangeMaxCap or (mode.rangeMaxCap and maxVal > mode.rangeMaxCap) then
      mode.rangeMaxCap = maxVal

      if mode.rangeMinCap == mode.rangeMaxCap then
        local magnitude = math.floor(math.log10(abs(mode.rangeMaxCap)))

        mode.rangeMaxCap = mode.rangeMaxCap + math.pow(10, magnitude - 1)
      end

      dirty = true
    end

    if not mode.rangeMin then
      mode.rangeMin = mode.rangeMinCap
      dirty = true
    end

    if not mode.rangeMax then
      mode.rangeMax = mode.rangeMaxCap
      dirty = true
    end
  end

  if requestDrawnNodesCallbacks and next(requestDrawnNodesCallbacks) ~= nil then
    for _, geFuncName in ipairs(requestDrawnNodesCallbacks) do
      obj:queueGameEngineLua(geFuncName .. "(" .. serialize(nodesDrawn) .. "," .. nodeScale .. ")")
    end
    table.clear(requestDrawnNodesCallbacks)
  end

  return dirty
end

local beamsDrawn
local function visualizeBeams()
  local dirty = false

  local modeID = M.state.vehicle.beamVisMode
  local mode = M.state.vehicle.beamVisModes[modeID]
  if not mode then return false end

  local modeName = mode.name

  local rangeMin = mode.rangeMin or -huge
  local rangeMax = mode.rangeMax or huge

  local minVal = huge
  local maxVal = -huge

  local beamScale = (mode.beamScale or 0.002) * M.state.vehicle.beamVisWidthScale
  local alpha = M.state.vehicle.beamVisAlpha

  beamsDrawn = beamsDrawn or {}
  table.clear(beamsDrawn)
  local bdi = 1

  -- "off"
  if modeID == 1 then return dirty end

  -- highlighted beams
  for i = 0, beamsCount - 1 do
    local beam = v.data.beams[i]
    if beam.highlight then
      obj.debugDrawProxy:drawBeam3d(beam.cid, beam.highlight.radius, parseColor(beam.highlight.col))
    end
  end
  if playerInfo.firstPlayerSeated then
    obj.debugDrawProxy:drawText2D(vec3(40, 60, 0), color(255, 165, 0, 255), "Mode: " .. modeName)
  end

  -- "simple"
  if modeID == 2 then
    for i = 0, beamsCount - 1 do
      local beam = v.data.beams[i]
      obj.debugDrawProxy:drawBeam3d(beam.cid, beamScale, color(0, 223, 0, 255 * alpha))

      beamsDrawn[bdi] = beam.cid
      bdi = bdi + 1
    end

  -- "type" | "with broken" | "broken only"
  elseif modeID == 3 or modeID == 4 or modeID == 5 then

    for i = 0, beamsCount - 1 do
      local beam = v.data.beams[i]
      local beamType = beam.beamType or 0

      local col = beamTypesColors[beamType]

      local beamBroken = obj:beamIsBroken(beam.cid)

      if (modeID == 4 or modeID == 5) and beamBroken then
        col = beamTypesColors[BEAM_BROKEN]
      end

      if (modeID == 3 and not beamBroken) or modeID == 4 or (modeID == 5 and beamBroken) then
        local r,g,b,a = colorGetRGBA(col)
        obj.debugDrawProxy:drawBeam3d(beam.cid, beamScale, color(r, g, b, a * alpha))

        beamsDrawn[bdi] = beam.cid
        bdi = bdi + 1
      end
    end

    -- Color legend
    if playerInfo.firstPlayerSeated and modeID ~= 5 then
      for i = 0, #beamTypesNames do
        obj.debugDrawProxy:drawText2D(vec3(40, 100 + i * 20, 0), beamTypesColors[i], beamTypesNames[i])
      end
    end

  -- "stress (old)"
  elseif modeID == 6 then
    for i = 0, beamsCount - 1 do
      local beam = v.data.beams[i]
      local stress = obj:getBeamStress(beam.cid) * 0.0002
      local a = min(1, abs(stress)) * 255 * alpha
      if a > 5 then
        local r = max(-1, min(0, stress)) * 255 * -1
        local b = max(0, min(1, stress)) * 255
        obj.debugDrawProxy:drawBeam3d(beam.cid, beamScale, color(r, 0, b, a))

        beamsDrawn[bdi] = beam.cid
        bdi = bdi + 1
      end
    end

    if playerInfo.firstPlayerSeated then
      obj.debugDrawProxy:drawText2D(vec3(40, 100, 0), color(255, 0, 0, 255), "Compression")
      obj.debugDrawProxy:drawText2D(vec3(40, 120, 0), color(0, 0, 255, 255), "Extension")
    end

  -- "stress (new)"
  elseif modeID == 7 then
    local scaler = 1 / (rangeMax - rangeMin)

    for i = 0, beamsCount - 1 do
      local beam = v.data.beams[i]
      local stress = obj:getBeamStressDamp(beam.cid)
      local absStress = abs(stress)

      if absStress >= rangeMin and absStress <= rangeMax then
        local a = (absStress - rangeMin) * scaler * 255
        if a > 5 then
          local r = max(-1, min(0, (stress + rangeMin) * scaler)) * 255 * -1 -- (red compression)
          local b = max(0, min(1, (stress - rangeMin) * scaler)) * 255 -- (blue extension)
          a = a * alpha
          obj.debugDrawProxy:drawBeam3d(beam.cid, beamScale, color(r, 0, b, a))

          beamsDrawn[bdi] = beam.cid
          bdi = bdi + 1
        end
      end
    end

    if playerInfo.firstPlayerSeated then
      obj.debugDrawProxy:drawText2D(vec3(40, 100, 0), color(255, 0, 0, 255), "Compression")
      obj.debugDrawProxy:drawText2D(vec3(40, 120, 0), color(0, 0, 255, 255), "Extension")
      obj.debugDrawProxy:drawText2D(vec3(40, 140, 0), color(255, 255, 255, 255), string.format("Range Min: %.2f", rangeMin))
      obj.debugDrawProxy:drawText2D(vec3(40, 160, 0), color(255, 255, 255, 255), string.format("Range Max: %.2f", rangeMax))
    end

  -- "displacement"
  elseif modeID == 8 then
    local scaler = 1 / (rangeMax - rangeMin)

    local nodePosCache = {}
    local tempVec = vec3()

    for i = 0, beamsCount - 1 do
      local beam = v.data.beams[i]

      tempVec:setSub2(v.data.nodes[beam.id2].pos, v.data.nodes[beam.id1].pos)
      local originalLength = tempVec:length()

      local nodePos1 = nodePosCache[beam.id1] or obj:getNodePosition(beam.id1)
      local nodePos2 = nodePosCache[beam.id2] or obj:getNodePosition(beam.id2)
      nodePosCache[beam.id1] = nodePos1
      nodePosCache[beam.id2] = nodePos2

      tempVec:setSub2(nodePos2, nodePos1)
      local currentLength = tempVec:length()
      local displacement = currentLength - originalLength
      local absDisplacement = abs(displacement)

      if absDisplacement >= rangeMin and absDisplacement <= rangeMax then
        local a = (absDisplacement - rangeMin) * scaler * 255
        if a > 5 then
          local r = max(-1, min(0, (displacement + rangeMin) * scaler)) * 255 * -1 -- (red compression)
          local b = max(0, min(1, (displacement - rangeMin) * scaler)) * 255 -- (blue extension)
          a = a * alpha
          obj.debugDrawProxy:drawBeam3d(beam.cid, beamScale, color(r, 0, b, a))

          beamsDrawn[bdi] = beam.cid
          bdi = bdi + 1
        end
      end
    end

    if playerInfo.firstPlayerSeated then
      obj.debugDrawProxy:drawText2D(vec3(40, 100, 0), color(255, 0, 0, 255), "Compression")
      obj.debugDrawProxy:drawText2D(vec3(40, 120, 0), color(0, 0, 255, 255), "Extension")
      obj.debugDrawProxy:drawText2D(vec3(40, 140, 0), color(255, 255, 255, 255),  string.format("Range Min: %.2f", rangeMin))
      obj.debugDrawProxy:drawText2D(vec3(40, 160, 0), color(255, 255, 255, 255),  string.format("Range Max: %.2f", rangeMax))
    end

  -- "deformation"
  elseif modeID == 9 then
    local deformRange = rangeMax - rangeMin
    for i = 0, beamsCount - 1 do
      local beam = v.data.beams[i]
      if not obj:beamIsBroken(beam.cid) then
        local deform = obj:getBeamDebugDeformation(beam.cid) - 1
        local absDeform = abs(deform)

        if absDeform >= rangeMin and absDeform <= rangeMax then
          local r = max(min((-deform - rangeMin) / deformRange, 1), 0) * 255
            --red for compression
          local b = max(min((deform - rangeMin) / deformRange, 1), 0) * 255
            --blue for elongation
          local a = min((absDeform - rangeMin) / deformRange, 1) * 255 * alpha
          obj.debugDrawProxy:drawBeam3d(beam.cid, beamScale, color(r, 0, b, a))

          beamsDrawn[bdi] = beam.cid
          bdi = bdi + 1
        end
      end
    end

    if playerInfo.firstPlayerSeated then
      obj.debugDrawProxy:drawText2D(vec3(40, 100, 0), color(255, 0, 0, 255), "Compression")
      obj.debugDrawProxy:drawText2D(vec3(40, 120, 0), color(0, 0, 255, 255), "Extension")
      obj.debugDrawProxy:drawText2D(vec3(40, 140, 0), color(255, 255, 255, 255),  string.format("Range Min: %.2f", rangeMin))
      obj.debugDrawProxy:drawText2D(vec3(40, 160, 0), color(255, 255, 255, 255),  string.format("Range Max: %.2f", rangeMax))
    end

  -- "breakgroups"
  elseif modeID == 10 then
    local groups = {}
    local wasDrawn = {}
    for i = 0, beamsCount - 1 do
      local beam = v.data.beams[i]
      if beam.breakGroup and beam.breakGroup ~= "" then
        local breakGroups = type(beam.breakGroup) == "table" and beam.breakGroup or {beam.breakGroup}
        for _, v in pairs(breakGroups) do
          if not groups[v] then
            groups[v] = i
            i = i + 1
          end
          local c = getContrastColor(groups[v], 255 * alpha)
          obj.debugDrawProxy:drawBeam3d(beam.cid, beamScale, c)
          if not wasDrawn[v] then
            obj.debugDrawProxy:drawNodeText(beam.id1, c, v, nodeDisplayDistance)
            wasDrawn[v] = 1
          end

          beamsDrawn[bdi] = beam.cid
          bdi = bdi + 1
        end
      end
    end

  -- "deformgroups"
  elseif modeID == 11 then
    local groups = {}
    local wasDrawn = {}
    for i = 0, beamsCount - 1 do
      local beam = v.data.beams[i]
      if beam.deformGroup and beam.deformGroup ~= "" then
        local deformGroups = type(beam.deformGroup) == "table" and beam.deformGroup or {beam.deformGroup}
        for _, v in pairs(deformGroups) do
          if not groups[v] then
            groups[v] = i
            i = i + 1
          end
          local c = getContrastColor(groups[v], 255 * alpha)
          obj.debugDrawProxy:drawBeam3d(beam.cid, beamScale, c)
          if not wasDrawn[v] then
            obj.debugDrawProxy:drawNodeText(beam.id1, c, v, nodeDisplayDistance)
            wasDrawn[v] = 1
          end

          beamsDrawn[bdi] = beam.cid
          bdi = bdi + 1
        end
      end
    end

  -- the rest
  elseif modeID >= 12 then
    -- Do rendering and get min/max values for next frame rendering
    for i = 0, beamsCount - 1 do
      local beam = v.data.beams[i]
      local val = tonumber(beam[modeName])

      if val then
        minVal = val ~= -huge and min(val, minVal) or minVal
        maxVal = val ~= huge and max(val, maxVal) or maxVal

        if val >= rangeMin and val <= rangeMax then
          local relValue = 1 / (rangeMax - rangeMin) * (val - rangeMin)
          relValue = relValue == huge and 1 or relValue
          relValue = relValue == -huge and 0 or relValue

          local r = (relValue + (1 - relValue)) * 255
          local g = (1 - relValue) * 255
          local b = (1 - relValue) * 255
          local a = alpha * 255

          obj.debugDrawProxy:drawBeam3d(beam.cid, beamScale, color(r, g, b, a))

          beamsDrawn[bdi] = beam.cid
          bdi = bdi + 1

        elseif abs(val) == huge and mode.showInfinity then
          local a = alpha * 255
          obj.debugDrawProxy:drawBeam3d(beam.cid, beamScale, color(255, 0, 255, a))

          beamsDrawn[bdi] = beam.cid
          bdi = bdi + 1
        end
      end
    end

    if playerInfo.firstPlayerSeated then
      obj.debugDrawProxy:drawText2D(vec3(40, 100, 0), color(255, 255, 255, 255), string.format("Range Min: %.2f", rangeMin))
      obj.debugDrawProxy:drawText2D(vec3(40, 120, 0), color(255, 0, 0, 255),     string.format("Range Max: %.2f", rangeMax))
      if mode.showInfinity then
        obj.debugDrawProxy:drawText2D(vec3(40, 140, 0), color(255, 0, 255, 255),  "Includes FLT_MAX")
      end
    end
  end

  -- If auto range enabled and at least one beam value exists, use it to calculate range min/max values
  if mode.autoRange and minVal ~= huge and maxVal ~= -huge then
    if not mode.rangeMinCap or (mode.rangeMinCap and minVal < mode.rangeMinCap) then
      mode.rangeMinCap = minVal
      dirty = true
    end

    if not mode.rangeMaxCap or (mode.rangeMaxCap and maxVal > mode.rangeMaxCap) then
      mode.rangeMaxCap = maxVal

      if mode.rangeMinCap == mode.rangeMaxCap then
        local magnitude = math.floor(math.log10(abs(mode.rangeMaxCap)))

        mode.rangeMaxCap = mode.rangeMaxCap + math.pow(10, magnitude - 1)
      end

      dirty = true
    end

    if not mode.rangeMin then
      mode.rangeMin = mode.rangeMinCap
      dirty = true
    end

    if not mode.rangeMax then
      mode.rangeMax = mode.rangeMaxCap
      dirty = true
    end
  end

  if requestDrawnBeamsCallbacks and next(requestDrawnBeamsCallbacks) ~= nil then
    for _, geFuncName in ipairs(requestDrawnBeamsCallbacks) do
      obj:queueGameEngineLua(geFuncName .. "(" .. serialize(beamsDrawn) .. "," .. beamScale .. ")")
    end
    table.clear(requestDrawnBeamsCallbacks)
  end

  return dirty
end

local function updateUIs()
  -- INTENTIONALLY CALLING FROM GAME ENGINE LUA TO WORKAROUND A BUG
  obj:queueGameEngineLua("guihooks.trigger('BdebugUpdate'," .. serialize(M.state) .. ")")

  -- This is fine though
  obj:queueGameEngineLua("extensions.hook('onBDebugUpdate'," .. serialize(M.state) .. ")")
end

local function debugDraw(focusPos)
  local dirty = false

  visualizeWheelThermals()
  visualizeTireContactPoint()
  visualizeCollisionTriangles()
  visualizeAerodynamics()
  visualizeCOG()

  visualizeNodesTexts()
  dirty = visualizeNodes() or dirty
  dirty = visualizeBeams() or dirty

  if dirty then
    updateUIs()
  end
end

local function updateDebugDraw()
  -- Only enable debugDraw if one of the modes are enabled and M.state.vehicleDebugVisible is true
  M.debugDraw = nop
  for k, v in pairs(M.state.vehicle) do
    if type(v) ~= "table" and v ~= M.initState.vehicle[k] and M.state.vehicleDebugVisible then
      M.debugDraw = debugDraw
      break
    end
  end

  -- "with broken" | "broken only"
  M.beamBroke = ((M.state.vehicle.beamVisMode == 4 or M.state.vehicle.beamVisMode == 5) and M.state.vehicleDebugVisible) and beamBroke or nop

  -- "deformation" | "deformgroups"
  M.beamDeformed = ((M.state.vehicle.beamVisMode == 9 or M.state.vehicle.beamVisMode == 10) and M.state.vehicleDebugVisible) and beamDeformed or nop
end

local function sendState()
  updateDebugDraw()
  updateUIs()
end

-- Request/send drawn nodes to GE Lua function
local function requestDrawnNodesGE(geFuncName)
  requestDrawnNodesCallbacks = requestDrawnNodesCallbacks or {}
  table.insert(requestDrawnNodesCallbacks, geFuncName)
end

-- Request/send drawn beams to GE Lua function
local function requestDrawnBeamsGE(geFuncName)
  requestDrawnBeamsCallbacks = requestDrawnBeamsCallbacks or {}
  table.insert(requestDrawnBeamsCallbacks, geFuncName)
end

local function onPlayersChanged(m)
  if m then
    sendState()
  end
end

local function setState(state)
  M.state.vehicleDebugVisible = false
  M.state = state
  M.state.vehicle = M.state.vehicle or deepcopy(M.initState.vehicle)
  for k, v in pairs(M.state.vehicle) do
    if type(v) ~= "table" and v ~= M.initState.vehicle[k] then
      M.state.vehicleDebugVisible = true
    end
  end

  sendState()
end

local function setMode(modeVar, modesVar, mode, doSendState)
  if M.state.vehicle[modeVar] and M.state.vehicle[modesVar] then
    if mode > #M.state.vehicle[modesVar] then
      mode = 1
    elseif mode < 1 then
      mode = #M.state.vehicle[modesVar]
    end

    M.state.vehicle[modeVar] = mode

    if mode ~= 1 then
      M.state.vehicleDebugVisible = true
    end
  end

  if doSendState then
    sendState()
  end
end

-- User input events

-- function used by the input subsystem - AND NOTHING ELSE
-- DO NOT use these from the UI
local function toggleEnabled()
  M.state.vehicleDebugVisible = not M.state.vehicleDebugVisible
  sendState()
end

local function nodetextModeChange(change)
  setMode("nodeTextMode", "nodeTextModes", M.state.vehicle.nodeTextMode + change, true)

  local modeName = M.state.vehicle.nodeTextModes[M.state.vehicle.nodeTextMode].name
  guihooks.message({txt = "vehicle.bdebug.nodeTextMode", context = {nodeTextMode = "vehicle.bdebug.nodeTextMode." .. modeName}}, 3, "debug")
end

local function nodevisModeChange(change)
  setMode("nodeVisMode", "nodeVisModes", M.state.vehicle.nodeVisMode + change, true)

  local modeName = M.state.vehicle.nodeVisModes[M.state.vehicle.nodeVisMode].name
  guihooks.message({txt = "vehicle.bdebug.nodeVisMode", context = {nodeVisMode = "vehicle.bdebug.nodeVisMode." .. modeName}}, 3, "debug")
end

local function skeletonModeChange(change)
  setMode("beamVisMode", "beamVisModes", M.state.vehicle.beamVisMode + change, true)

  local modeName = M.state.vehicle.beamVisModes[M.state.vehicle.beamVisMode].name
  guihooks.message({txt = "vehicle.bdebug.beamVisMode", context = {beamVisMode = "vehicle.bdebug.beamVisMode." .. modeName}}, 3, "debug")
end

-- OTHER PLACES ARE USING THIS but it was useless to begin with so just leaving here to prevent errors for now!
local function meshVisChange(val, isAbsoluteValue)
end

local function toggleColTris()
  M.state.vehicle.collisionTriangle = not M.state.vehicle.collisionTriangle
  if M.state.vehicle.collisionTriangle ~= M.initState.vehicle.collisionTriangle then
    M.state.vehicleDebugVisible = true
  end
  if M.state.vehicle.collisionTriangle then
    guihooks.message("vehicle.bdebug.trisOn", 3, "debug")
  else
    guihooks.message("vehicle.bdebug.trisOff", 3, "debug")
  end

  sendState()
end

local function cogChange(change)
  setMode("cogMode", "cogModes", M.state.vehicle.cogMode + change, true)

  local modeName = M.state.vehicle.cogModes[M.state.vehicle.cogMode].name
  guihooks.message({txt = "vehicle.bdebug.cogMode", context = {cogMode = "vehicle.bdebug.cogMode." .. modeName}}, 3, "debug")
end

local function resetModes()
  M.state = deepcopy(M.initState)
  guihooks.message("vehicle.bdebug.clear", 3, "debug")
  sendState()
end

local function init()
  nodesCount = tableSizeC(v.data.nodes)
  beamsCount = tableSizeC(v.data.beams)

  M.state = deepcopy(M.initState)

  sendState()
end

local function reset()

end

local function onSerialize()
  return {
    state = M.state
  }
end

local function onDeserialize(data)
  M.state = data.state
end

M.selectNode = selectNode
M.nodeCollision = nop
M.beamBroke = nop
M.beamDeformed = nop

M.debugDrawNode = debugDrawNode
M.debugDraw = nop
M.requestState = sendState
M.requestDrawnNodesGE = requestDrawnNodesGE
M.requestDrawnBeamsGE = requestDrawnBeamsGE
M.onPlayersChanged = onPlayersChanged
M.setState = setState

M.toggleEnabled = toggleEnabled
M.nodetextModeChange = nodetextModeChange
M.nodevisModeChange = nodevisModeChange
M.skeletonModeChange = skeletonModeChange
M.meshVisChange = meshVisChange
M.toggleColTris = toggleColTris
M.cogChange = cogChange
M.resetModes = resetModes

M.init = init
M.reset = reset

M.onSerialize = onSerialize
M.onDeserialize = onDeserialize

return M