-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- [[ STORE FREQUENTLY USED FUNCTIONS IN UPVALUES ]] --
local max = math.max
local min = math.min
local sin = math.sin
local asin = math.asin
local pi = math.pi
local abs = math.abs
local sqrt = math.sqrt
local floor = math.floor
local tableInsert = table.insert
local tableRemove = table.remove
local tableConcat = table.concat
local strFormat = string.format
---------------------------------
local scriptai = nil

local M = {}

M.mode = 'disabled' -- this is the main mode
M.manualTargetName = nil
M.debugMode = 'off'
M.speedMode = nil
M.routeSpeed = nil
M.extAggression = 0.3
M.cutOffDrivability = 0
M.driveInLaneFlag = 'off'

-- [[ Simulation time step]] --
local dt

-- [[ ENVIRONMENT VARIABLES ]] --
-- Prevents division by zero gravity
local gravity = obj:getGravity()
gravity = max(0.1, abs(gravity)) * sign2(gravity)

local g = abs(gravity)
local gravityDir = vec3(0, 0, sign2(gravity))
local gravityVec = gravityDir * g
----------------------------------

-- [[ PERFORMANCE RELATED ]] --
local aggression = 1
local aggressionMode
--------------------------------------------------------------------------

-- [[ AI DATA: POSITION, CONTROL, STATE ]] --
local aiPos = obj:getFrontPosition()
local aiDirVec = obj:getDirectionVector()
local ai = {
  vel = vec3(obj:getSmoothRefVelocityXYZ()),
  prevDirVec = vec3(aiDirVec),
  upVec = obj:getDirectionVectorUp(),
  rightVec = vec3(),
  width = nil,
  length = nil,
  wheelBase = nil,
  currentSegment = {},
}
local aiSpeed = ai.vel:length()

local targetSpeedDifSmoother = nil
local aiDeviation = 0
local aiDeviationSmoother = newTemporalSmoothing(1)
local smoothTcs = newTemporalSmoothingNonLinear(0.1, 0.9)
local throttleSmoother = newTemporalSmoothing(1e30, 0.2)
local aiCannotMoveTime = 0
local aiForceGoFrontTime = 0
local staticFrictionCoef = 1
local threewayturn = {state = 0, speedDifInt = 0}

local forces = {}

local lastCommand = {steering = 0, throttle = 0, brake = 0, parkingbrake = 0}

local driveInLaneFlag = false
local internalState = 'onroad'

local restoreGearboxMode = false
local validateInput = nop
------------------------------

-- [[ CRASH DETECTION ]] --
local crash = {time = 0, manoeuvre = 0, dir = nil}

-- [[ OPPONENT DATA ]] --
local player
local chaseData = {playerState = nil, playerStoppedTimer = 0, playerRoad = nil}

-- [[ SETTINGS, PARAMETERS, AUXILIARY DATA ]] --
local mapData -- map data including node connections (edges and edge data), node positions and node radii
local signalsData -- traffic intersection and signals data
local currentRoute
local MIN_PLAN_COUNT = 3
local targetWPName

local wpList, manualPath, speedList
local race, noOfLaps
local parameters

local targetObjectSelectionMode

local edgeDict

------------------------------

-- [[ TRAFFIC ]] --
local trafficTable = {}
local trafficBlock, trafficSide, trafficAction, intersection
local avoidCars = 'on'
M.extAvoidCars = 'auto'
local changePlanTimer = 0

-----------------------

-- [[ HEAVY DEBUG MODE ]] --
local trajecRec = {last = 0}
local routeRec = {last = 0}
local labelRenderDistance = 10
-- local newPositionsDebug = {} -- for debug purposes
local misc = {logData = nop}
------------------------------

local function cross(a, b)
  return a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x
end

local function aistatus(status, category)
  guihooks.trigger("AIStatusChange", {status=status, category=category})
end

local function getState()
  return M
end

local function stateChanged()
  if playerInfo.anyPlayerSeated then
    guihooks.trigger("AIStateChange", getState())
  end
end

local function setSpeed(speed)
  if type(speed) ~= 'number' then M.routeSpeed = nil else M.routeSpeed = speed end
end

local function setSpeedMode(speedMode)
  if speedMode == 'set' or speedMode == 'limit' or speedMode == 'legal' or speedMode == 'off' then
    M.speedMode = speedMode
  else
    M.speedMode = nil
  end
end

local function resetSpeedModeAndValue()
  M.speedMode = nil -- maybe this should be 'off'
  M.routeSpeed = nil
end

local function setAggressionInternal(v)
  aggression = v or M.extAggression
end

local function setAggressionExternal(v)
  M.extAggression = v or M.extAggression
  setAggressionInternal()
  stateChanged()
end

local function setAggressionMode(aggrmode)
  if aggrmode == 'rubberBand' then
    aggressionMode = aggrmode
  else
    aggressionMode = nil
    setAggressionInternal()
  end
end

local function resetAggression()
  setAggressionInternal()
end

local function resetTrafficTables()
  trafficBlock = {timer = 0, coef = 0, timerLimit = 6, block = false}
  trafficSide = {timer = 0, cTimer = 0, side = 1, displacement = 0, timerLimit = 6}
  trafficAction = {hornTimer = -1, hornTimerLimit = 1, forcedStop = false}
  intersection = {timer = 0, turn = 0, block = false}

  if electrics.values.horn == 1 then electrics.horn(false) end
  if electrics.values.signal_left_input or electrics.values.signal_right_input then electrics.set_warn_signal(false) end
end
resetTrafficTables()

local function resetParameters()
  -- parameters are used for detailed values and actions of ai
  parameters = {
    turnForceCoef = 2, -- coefficient for curve spring forces
    awarenessForceCoef = 0.25, -- coefficient for vehicle awareness displacement
    edgeDist = 0, -- minimum distance from the edge of the road
    trafficWaitTime = 2, -- traffic delay after stopping at intersection
    enableElectrics = true, -- allows the ai to automatically use electrics such as hazard lights (especially for traffic)
    driveStyle = 'default',
    staticFrictionCoefMult = 0.95,
    lookAheadKv = 0.65,
  }
end
resetParameters()

local function setParameters(data)
  tableMerge(parameters, data)
end

local function setTargetObjectID(id)
  M.targetObjectID = M.targetObjectID ~= objectId and id or -1
  if M.targetObjectID ~= -1 then targetObjectSelectionMode = 'manual' end
end

local function calculateWheelBase()
  local avgWheelNodePos, numOfWheels = vec3(), 0
  for _, wheel in pairs(wheels.wheels) do
    -- obj:getNodePosition is the pos vector of querry node (wheel.node1) relative to ref node in world coordinates
    avgWheelNodePos:setAdd(obj:getNodePosition(wheel.node1))
    numOfWheels = numOfWheels + 1
  end
  avgWheelNodePos:setScaled(1 / numOfWheels)

  local aiDirVec = obj:getDirectionVector()
  local avgFrontWheelPos, frontWheelCount = vec3(), 0
  local avgBackWheelPos, backWheelCount = vec3(), 0
  for _, wheel in pairs(wheels.wheels) do
    local wheelPos = obj:getNodePosition(wheel.node1)
    if wheelPos:dot(aiDirVec) > avgWheelNodePos:dot(aiDirVec) then
      avgFrontWheelPos:setAdd(wheelPos)
      frontWheelCount = frontWheelCount + 1
    else
      avgBackWheelPos:setAdd(wheelPos)
      backWheelCount = backWheelCount + 1
    end
  end

  avgFrontWheelPos:setScaled(1 / frontWheelCount)
  avgBackWheelPos:setScaled(1 / backWheelCount)

  return avgFrontWheelPos:distance(avgBackWheelPos)
end

local function updatePlayerData()
  mapmgr.getObjects()
  if mapmgr.objects[M.targetObjectID] and targetObjectSelectionMode == 'manual' then
    player = mapmgr.objects[M.targetObjectID]
    player.id = M.targetObjectID
  elseif tableSize(mapmgr.objects) == 2 then
    if player ~= nil then
      player = mapmgr.objects[player.id]
    else
      for k, v in pairs(mapmgr.objects) do
        if k ~= objectId then
          M.targetObjectID = k
          player = v
          break
        end
      end
      targetObjectSelectionMode = 'auto'
    end
  else
    if player ~= nil and player.active == true then
      player = mapmgr.objects[player.id]
    else
      for k, v in pairs(mapmgr.objects) do
        if k ~= objectId and v.active == true then
          M.targetObjectID = k
          player = v
          break
        end
      end
      targetObjectSelectionMode = 'targetActive'
    end
  end
  mapmgr.objects[objectId] = mapmgr.objects[objectId] or {pos = aiPos, dirVec = aiDirVec}
end

local function driveCar(steering, throttle, brake, parkingbrake)
  input.event("steering", steering, "FILTER_AI")
  input.event("throttle", throttle, "FILTER_AI")
  input.event("brake", brake, "FILTER_AI")
  input.event("parkingbrake", parkingbrake, "FILTER_AI")

  lastCommand.steering = steering
  lastCommand.throttle = throttle
  lastCommand.brake = brake
  lastCommand.parkingbrake = parkingbrake
end

local function driveToTarget(targetPos, throttle, brake, targetSpeed)
  if not targetPos then return end

  local plan = currentRoute and currentRoute.plan
  targetSpeed = targetSpeed or plan and plan.targetSpeed
  if not targetSpeed then return end

  local targetVec = targetPos - aiPos; targetVec:normalize()
  local dirAngle = asin(ai.rightVec:dot(targetVec))

  -- oversteer
  local throttleCoef = 1
  if aiSpeed > 1 then
    local rightVel = ai.rightVec:dot(ai.vel)
    if rightVel * ai.rightVec:dot(targetPos - aiPos) > 0 then
      local rotVel = min(1, (ai.prevDirVec:projectToOriginPlane(ai.upVec):normalized()):distance(aiDirVec) * dt * 10000)
      throttleCoef = throttleCoef * max(0, 1 - abs(rightVel * aiSpeed * 0.05) * min(1, dirAngle * dirAngle * aiSpeed * 6) * rotVel)
    end
  end

  local dirVel = ai.vel:dot(aiDirVec)
  local absAiSpeed = abs(dirVel)
  local brakeCoef = 1

  if plan and plan[3] and dirVel > 3 then
    local p1, p2 = plan[1].pos, plan[2].pos
    local p2p1DirVec = p2 - p1; p2p1DirVec:normalize()

    local tp2 = (plan.targetSeg or 0) > 1 and targetPos or plan[3].pos
    local targetSide = (tp2 - p2):dot(p2p1DirVec:cross(ai.upVec))

    local outDeviation = aiDeviationSmoother:value() - aiDeviation * sign(targetSide)
    outDeviation = sign(outDeviation) * min(1, abs(outDeviation))
    aiDeviationSmoother:set(outDeviation)
    aiDeviationSmoother:getUncapped(0, dt)

    if outDeviation > 0 and absAiSpeed > 3 then
      local steerCoef = outDeviation * absAiSpeed * absAiSpeed * min(1, dirAngle * dirAngle * 4)
      local understeerCoef = max(0, steerCoef) * min(1, abs(ai.vel:dot(p2p1DirVec) * 3))
      local noUndersteerCoef = max(0, 1 - understeerCoef)
      throttleCoef = throttleCoef * noUndersteerCoef
      brakeCoef = min(brakeCoef, max(0, 1 - understeerCoef * understeerCoef))
    end
  else
    aiDeviationSmoother:set(0)
  end

  -- wheel speed
  if absAiSpeed > 0.05 then
    if sensors.gz <= 0.1 then
      local totalSlip = 0
      local propSlip = 0
      local totalDownForce = 0
      local lwheels = wheels.wheels
      for i = 0, tableSizeC(lwheels) - 1 do
        local wd = lwheels[i]
        if not wd.isBroken then
          local lastSlip = wd.lastSlip
          local downForce = wd.downForceRaw
          totalSlip = totalSlip + lastSlip * downForce
          totalDownForce = totalDownForce + downForce
          if wd.isPropulsed then
            propSlip = max(propSlip, lastSlip)
          end
        end
      end

      absAiSpeed = max(absAiSpeed, 3)

      totalSlip = totalSlip * 4 / (totalDownForce + 1e-25)

      -- abs
      brakeCoef = brakeCoef * square(max(0, absAiSpeed - totalSlip) / absAiSpeed)

      -- tcs
      local tcsCoef = max(0, absAiSpeed - propSlip * propSlip) / absAiSpeed
      throttleCoef = throttleCoef * min(tcsCoef, smoothTcs:get(tcsCoef, dt))
    else
      brakeCoef = 0
      throttleCoef = 0
    end
  end

  local dirTarget = aiDirVec:dot(targetVec)

  if crash.manoeuvre == 1 and dirTarget < aiDirVec:dot(crash.dir) then
    driveCar(-fsign(dirAngle), brake * brakeCoef, throttle * throttleCoef, 0)
    return
  else
    crash.manoeuvre = 0
  end

  if parameters.driveStyle == 'offRoad' then
    brakeCoef = 1
    throttleCoef = sqrt(throttleCoef)
  end

  aiForceGoFrontTime = max(0, aiForceGoFrontTime - dt)
  if threewayturn.state == 1 and aiCannotMoveTime > 1 and aiForceGoFrontTime == 0 then
    threewayturn.state = 0
    aiCannotMoveTime = 0
    aiForceGoFrontTime = 2
  end

  if aiForceGoFrontTime > 0 and dirTarget < 0 then
    dirTarget = -dirTarget
    dirAngle = -dirAngle
  end

  if (dirTarget < 0 or (dirTarget < 0.15 and threewayturn.state == 1)) and currentRoute then
    local n1, n2, n3 = plan[1], plan[2], plan[3]
    local edgeDist = min((n2 or n1).radiusOrig, n1.radiusOrig) - aiPos:z0():distanceToLine((n3 or n2).posOrig:z0(), n2.posOrig:z0())
    if edgeDist > ai.width and threewayturn.state == 0 then
      driveCar(fsign(dirAngle), 0.5 * throttleCoef, 0, min(max(aiSpeed - 3, 0), 1))
    else
      if threewayturn.state == 0 then
        threewayturn.state = 1
        threewayturn.speedDifInt = 0
      end
      local angleModulation = min(max(0, -(dirTarget-0.15)), 1)
      local speedDif = (10 * aggression * angleModulation) - aiSpeed
      threewayturn.speedDifInt = threewayturn.speedDifInt + speedDif * dt
      local pbrake = clamp(sign2(aiDirVec:dot(gravityDir) - 0.17), 0, 1) -- apply parking brake if reversing on an incline >~ 10 deg
      driveCar(-sign2(dirAngle), 0, clamp(0.05 * speedDif + 0.01 * threewayturn.speedDifInt, 0, 1), pbrake)
    end
  else
    threewayturn.state = 0
    local pbrake
    if ai.vel:dot(aiDirVec) < 0 and aiSpeed > 0.1 then
      if aiSpeed < 0.15 and targetSpeed <= 1e-5 then
        pbrake = 1
      else
        pbrake = 0
      end
      throttle = 0.5 * throttleCoef
      brake = 0
    else
      if (aiSpeed > 4 and aiSpeed < 30 and abs(dirAngle) > 0.97 and brake == 0) or (aiSpeed < 0.15 and targetSpeed <= 1e-5) then
        pbrake = 1
      else
        pbrake = 0
      end
      throttle = throttle * throttleCoef
      brake = brake * brakeCoef
    end

    local aggSq = square(aggression + max(0, -(aiDirVec:dot(gravityDir))))
    local rate = max(throttleSmoother[throttleSmoother:value() < throttle], 10 * aggSq * aggSq)
    throttle = throttleSmoother:getWithRateUncapped(throttle, dt, rate)

    driveCar(dirAngle, throttle, brake, pbrake)
  end
end

local function posOnPlan(pos, plan, dist)
  if not plan then return end
  dist = dist or 4
  dist = dist * dist
  local bestSeg, bestXnorm, bestDist
  for i = 1, #plan-2 do
    local p0, p1 = plan[i].pos, plan[i+1].pos
    local xnorm1 = pos:xnormOnLine(p0, p1)
    if xnorm1 > 0 then
      local p2 = plan[i+2].pos
      local xnorm2 = pos:xnormOnLine(p1, p2)
      if xnorm1 < 1 then -- contained in segment i
        if xnorm2 > 0 then -- also partly contained in segment i+1
          local sqDistFromP1 = pos:squaredDistance(p1)
          if sqDistFromP1 <= dist then
            bestSeg = i
            bestXnorm = 1
            break -- break inside conditional
          end
        else
          local sqDistFromLine = pos:squaredDistance(p0 + (p1 - p0) * xnorm1)
          if sqDistFromLine <= dist then
            bestSeg = i
            bestXnorm = xnorm1
          end
          break -- break should be outside above conditional
        end
      elseif xnorm2 < 0 then
        local sqDistFromP1 = pos:squaredDistance(p1)
        if sqDistFromP1 <= dist then
          bestSeg = i
          bestXnorm = 1
        end
        break -- break outside conditional
      end
    else
      break
    end
  end

  return bestSeg, bestXnorm
end

local function aiPosOnPlan(plan)
  local planCount = plan.planCount
  local aiSeg = 1
  local aiXnormOnSeg = 0
  for i = 1, planCount-1 do
    local p0Pos, p1Pos = plan[i].pos, plan[i+1].pos
    local xnorm = aiPos:xnormOnLine(p0Pos, p1Pos)
    if xnorm < 1 then
      if i < planCount - 2 then
        local nextXnorm = aiPos:xnormOnLine(p1Pos, plan[i+2].pos)
        if nextXnorm >= 0 then
          local p1Radius = plan[i+1].radiusOrig
          if aiPos:squaredDistance(linePointFromXnorm(p1Pos, plan[i+2].pos, nextXnorm)) <
              square(ai.width + lerp(p1Radius, plan[i+2].radiusOrig, min(1, nextXnorm))) then
            aiXnormOnSeg = nextXnorm
            aiSeg = i + 1
            break
          end
        end
      end
      aiXnormOnSeg = xnorm
      aiSeg = i
      break
    end
  end

  local disp = 0
  if aiSeg > 1 then
    local sumLen = 0
    disp = aiSeg - 1
    for i = 1, disp do
      sumLen = sumLen + plan[i].length
    end

    for i = 1, plan.planCount do
      plan[i] = plan[i+disp]
    end

    plan.planCount = plan.planCount - disp
    plan.planLen = max(0, plan.planLen - sumLen)
    plan.stopSeg = plan.stopSeg and max(1, plan.stopSeg - disp)
  end

  plan.aiXnormOnSeg = aiXnormOnSeg
  plan.aiSeg = aiSeg - disp
end

local function planSegAtDist(plan, dist)
  local planSeg = plan.planCount - 1
  dist = dist - plan[1].length * (1 - plan.aiXnormOnSeg)

  if dist <= 0 then
    return 1
  end

  for i = 2, plan.planCount - 1 do
    dist = dist - plan[i-1].length
    if dist <= 0 then
      planSeg = i
      break
    end
  end

  return planSeg, dist
end

local function calculateTarget(plan)
  aiPosOnPlan(plan)
  local targetLength = max(aiSpeed * parameters.lookAheadKv, 4.5)

  if plan.planCount >= 3 then
    local xnorm = clamp(plan.aiXnormOnSeg, 0, 1)
    targetLength = max(targetLength, plan[1].length * (1 - xnorm), plan[2].length * xnorm)
  end

  local remainder = targetLength

  local targetPos = vec3(plan[plan.planCount].pos)
  local targetSeg = max(1, plan.planCount-1)
  local prevPos = linePointFromXnorm(plan[1].pos, plan[2].pos, plan.aiXnormOnSeg) -- aiPos

  local segVec, segLen = vec3(), nil
  for i = 2, plan.planCount do
    local pos = plan[i].pos

    segVec:setSub2(pos, prevPos)
    segLen = segLen or segVec:length()

    if remainder <= segLen then
      targetSeg = i - 1
      targetPos:setScaled2(segVec, remainder / (segLen + 1e-30)); targetPos:setAdd(prevPos)

      -- smooth target
      local xnorm = clamp(targetPos:xnormOnLine(prevPos, pos), 0, 1)
      local lp_n1n2 = linePointFromXnorm(prevPos, pos, xnorm * 0.5 + 0.25)
      if xnorm <= 0.5 then
        if i >= 3 then
          targetPos = linePointFromXnorm(linePointFromXnorm(plan[i-2].pos, prevPos, xnorm * 0.5 + 0.75), lp_n1n2, xnorm + 0.5)
        end
      else
        if i <= plan.planCount - 2 then
          targetPos = linePointFromXnorm(lp_n1n2, linePointFromXnorm(pos, plan[i+1].pos, xnorm * 0.5 - 0.25), xnorm - 0.5)
        end
      end
      break
    end

    prevPos = pos
    remainder = remainder - segLen
    segLen = plan[i].length
  end

  plan.targetPos = targetPos
  plan.targetSeg = targetSeg
end

local function targetsCompatible(baseRoute, newRoute)
  local baseTvec = baseRoute.plan.targetPos - aiPos
  local newTvec = newRoute.plan.targetPos - aiPos
  if aiSpeed < 2 then return true end
  if newTvec:dot(aiDirVec) * baseTvec:dot(aiDirVec) <= 0 then return false end
  local baseTargetRight = baseTvec:cross(ai.upVec); baseTargetRight:normalize()
  return abs(newTvec:normalized():dot(baseTargetRight)) * aiSpeed < 2
end

local function getMinPlanLen(limLow, speed, accelg)
  -- given current speed, distance required to come to a stop if I can decelerate at 0.2g
  limLow = limLow or 150
  speed = speed or aiSpeed
  accelg = max(0.2, accelg or 0.2)
  return min(550, max(limLow, 0.5 * speed * speed / (accelg * g)))
end

local function pickAiWp(wp1, wp2, dirVec)
  dirVec = dirVec or aiDirVec
  local vec1 = mapData.positions[wp1] - aiPos
  local vec2 = mapData.positions[wp2] - aiPos
  local dot1 = vec1:dot(dirVec)
  local dot2 = vec2:dot(dirVec)
  if (dot1 * dot2) <= 0 then
    if dot1 < 0 then
      return wp2, wp1
    end
  else
    if vec2:squaredLength() < vec1:squaredLength() then
      return wp2, wp1
    end
  end
  return wp1, wp2
end

local function pathExtend(path, newPath)
  if newPath == nil then return end
  local pathCount = #path
  if path[pathCount] ~= newPath[1] then return end
  pathCount = pathCount - 1
  for i = 2, #newPath do
    path[pathCount+i] = newPath[i]
  end
end

-- http://cnx.org/contents/--TzKjCB@8/Projectile-motion-on-an-inclin
local function projectileSqSpeedToRangeRatio(pos1, pos2, pos3)
  local sinTheta = (pos2.z - pos1.z) / pos1:distance(pos2)
  local sinAlpha = (pos3.z - pos2.z) / pos2:distance(pos3)
  local cosAlphaSquared = max(1 - sinAlpha * sinAlpha, 0)
  local cosTheta = sqrt(max(1 - sinTheta * sinTheta, 0)) -- in the interval theta = {-pi/2, pi/2} cosTheta is always positive
  return 0.5 * g * cosAlphaSquared / max(cosTheta * (sinTheta*sqrt(cosAlphaSquared) - cosTheta*sinAlpha), 0)
end

local function inCurvature(vec1, vec2)
  --[[
    Given three points A, B, C (with AB being the vector from A to B), the curvature (= 1 / radius)
    of the circle going through them is:

    curvature = 2 * (AB x BC) / ( |AB| * |BC| * |CA| ) =>
              = 2 * |AB| * |BC| * Sin(th) / ( |AB| * |BC| * |CA| ) =>
              = 2 * (+/-) * sqrt ( 1 - Cos^2(th) ) / |CA| =>
              = 2 * (+/-) sqrt [ ( 1 - Cos^2(th) ) / |CA|^2 ) ] -- This is an sqrt optimization step

    In the calculation below the (+/-) which indicates the turning direction (direction of AB x BC) has been dropped
  --]]

  local vec1Sqlen, vec2Sqlen = vec1:squaredLength(), vec2:squaredLength()
  local dot12 = vec1:dot(vec2)
  local cos8sq = min(1, dot12 * dot12 / max(1e-30, vec1Sqlen * vec2Sqlen))

  if dot12 < 0 then -- angle between the two segments is acute
    local minDsq = min(vec1Sqlen, vec2Sqlen)
    local maxDsq = minDsq / max(1e-30, cos8sq)
    if max(vec1Sqlen, vec2Sqlen) > (minDsq + maxDsq) * 0.5 then
      if vec1Sqlen > vec2Sqlen then
        vec1, vec2 = vec2, vec1
        vec1Sqlen, vec2Sqlen = vec2Sqlen, vec1Sqlen
      end
      vec2:setScaled(sqrt(0.5 * (minDsq + maxDsq) / max(1e-30, vec2Sqlen)))
    end
  end

  vec2:setScaled(-1)
  return 2 * sqrt((1 - cos8sq) / max(1e-30, vec1:squaredDistance(vec2)))
end

local function getPathLen(path, startIdx, stopIdx)
  if not path then return end
  startIdx = startIdx or 1
  stopIdx = stopIdx or #path
  local positions = mapData.positions
  local pathLen = 0
  for i = startIdx+1, stopIdx do
    pathLen = pathLen + positions[path[i-1]]:distance(positions[path[i]])
  end

  return pathLen
end

local function getPathBBox(path, startIdx, stopIdx)
  if not path then return end
  startIdx = startIdx or 1
  stopIdx = stopIdx or #path

  local positions = mapData.positions
  local p = positions[path[startIdx]]
  local v = positions[path[stopIdx]] + p; v:setScaled(0.5)
  local r = getPathLen(path, startIdx, stopIdx) * 0.5

  return {v.x - r, v.y - r, v.x + r, v.y + r}, v, r
end

local function waypointInPath(path, waypoint, startIdx, stopIdx)
  if not path or not waypoint then return end
  startIdx = startIdx or 1
  stopIdx = stopIdx or #path
  for i = startIdx, stopIdx do
    if path[i] == waypoint then
      return i
    end
  end
end

local function getPlanLen(plan, from, to)
  from = max(1, from or 1)
  to = min(plan.planCount-1, to or (plan.planCount-1))
  local planLen = 0
  for i = from, to do
    planLen = planLen + plan[i].length
  end

  return planLen
end

local function updatePlanLen(plan, j, k)
  -- bulk recalculation of plan edge lengths and length of entire plan
  -- j: index of earliest node position that has changed
  -- k: index of latest node position that has changed
  j = max((j or 1) - 1, 1)
  k = min(k or plan.planCount, plan.planCount-1)

  local planLen = plan.planLen
  for i = j, k do
    local edgeLen = plan[i+1].pos:distance(plan[i].pos)
    planLen = planLen - plan[i].length + edgeLen
    plan[i].length = edgeLen
  end
  plan.planLen = planLen
end

local function roadNaturalContinuation(plan, wp1, wp2)
  if not plan or wp1 == nil or wp2 == nil then
    return
  end

  local positions = mapData.positions
  local data1 = mapData.graph[wp1][wp2]
  local wp2pos = positions[wp2]
  local dir1 = wp2pos - positions[wp1]; dir1:normalize()
  local width1 = mapData.radius[wp2]
  local lanesLeft1 = 2
  local lanesRight1 = 2
  -- local outNode1 = mapData.graph[wp1][wp2].inNode -- one way or not
  local minDiff = math.huge
  local minNode
  local w1, w2, w3 = 1, 1, 1
  local lastPlanPos = plan[plan.planCount].pos
  local dir2 = vec3()
  for k, v in pairs(mapData.graph[wp2]) do
    if k ~= wp1 then
      dir2:setSub2(positions[k], lastPlanPos); dir2:normalize()
      local dirDiff = sqrt(0.5 * (1 - dir2:dot(dir1)))
      local widthDiff = abs(mapData.radius[k] - width1) / max(mapData.radius[k], width1)
      local laneDiff = 0
      local totalDiff = w1 * dirDiff + w2 * widthDiff + w3 * laneDiff
      if totalDiff < minDiff then
        minDiff = totalDiff
        minNode = k
      end
    end
  end

  return minNode
end

local function laneChange(plan, dist, signedDisp, startNode, endNode, commitToLane)
  if not plan and currentRoute then
    plan = currentRoute.plan
  end

  if not plan then return end

  startNode = startNode or 1
  endNode = endNode or plan.planCount

  -- Apply node displacement
  local curDist, normalDispVec = 0, vec3()
  for i = startNode+1, endNode do
    curDist = min(curDist + plan[i-1].length, dist)
    normalDispVec:setScaled2(plan[i].normal, signedDisp * min(curDist / (dist + 1e-30), 1))
    plan[i].pos:setAdd(normalDispVec)
    plan[i].lane = 0
  end

  -- Recalculate vec and dirVec
  for i = startNode+1, min(endNode+1, plan.planCount) do
    plan[i].vec:setSub2(plan[i-1].pos, plan[i].pos); plan[i].vec.z = 0
    plan[i].dirVec:set(plan[i].vec)
    plan[i].dirVec:normalize()
  end

  -- if after a lane change a node is well within the new lane limits then commit to that lane
  if commitToLane then
    local dispSign = sign2(signedDisp)
    local posOrigToPosVec = vec3()
    for i = endNode, startNode+1, -1 do
      local node = plan[i]
      if node.oneWay and node.radiusOrig > 2.7 then
        posOrigToPosVec:setSub2(plan[i].pos, plan[i].posOrig)
        local dotSign = sign2(posOrigToPosVec:dot(plan[i].normal))
        if dotSign == dispSign and posOrigToPosVec:squaredDistance(plan[i].posOrig) > square(ai.width * 0.5) then -- TODO: second condition here does not look correct
          plan[i].lane = dotSign
        else
          break
        end
      else
        break
      end
    end
  end

  updatePlanLen(plan, startNode+1, endNode)

  --[[ For debugging
  table.clear(newPositionsDebug)
  for i = 1, #newPositions do
    newPositionsDebug[i] = vec3(newPositions[i])
  end
  --]]
end

local function setStopPoint(plan, dist)
  if not plan and currentRoute then
    plan = currentRoute.plan
  end
  if not plan then return end

  plan.stopSeg = dist and planSegAtDist(plan, dist)
end

local function buildNextRoute(plan, path)
  local planCount = plan.planCount
  local nextPathIdx = (plan[planCount].pathidx or 0) + 1 -- if the first plan node is the aiPos it does not have a pathidx value yet

  if race == true and noOfLaps and noOfLaps > 1 and not path[nextPathIdx] then -- in case the path loops
    local loopPathId
    local pathCount = #path
    local lastWayPoint = path[pathCount]
    for i = 1, pathCount do
      if lastWayPoint == path[i] then
        loopPathId = i
        break
      end
    end
    nextPathIdx = 1 + loopPathId -- nextPathIdx % #path
    noOfLaps = noOfLaps - 1
  end

  local nextNodeName = path[nextPathIdx]
  if not nextNodeName then return end
  local graph = mapData.graph

  local n1Pos, n1Radius, oneWay
  local n2 = graph[nextNodeName]
  if not n2 then return end
  local n2Pos = vec3(mapData.positions[nextNodeName])
  local n2Radius = mapData.radius[nextNodeName]
  local n2biNormal = mapmgr.surfaceNormalBelow(n2Pos, n2Radius * 0.5); n2biNormal:setScaled(-1)
  local wayPointAhead = path[nextPathIdx+1]

  if path[nextPathIdx-1] then
    n1Pos = mapData.positions[path[nextPathIdx-1]]
    n1Radius = mapData.radius[path[nextPathIdx-1]]
    local link = mapData.graph[path[nextPathIdx-1]][path[nextPathIdx]]
    local roadSpeedLimit
    if link then
      oneWay = link.inNode
      if nextPathIdx > 2 then
        roadSpeedLimit = min(link.speedLimit, mapData.graph[path[nextPathIdx-1]][path[nextPathIdx-2]].speedLimit)
      else
        roadSpeedLimit = link.speedLimit
      end
    end
    plan[planCount].roadSpeedLimit = roadSpeedLimit
  elseif wayPointAhead then -- if previous plan node is the aiPos then get oneWay data from path segment ahead of nextPathIdx
    n1Pos = vec3(aiPos)
    n1Radius = 2
    oneWay = mapData.graph[path[nextPathIdx]][wayPointAhead].inNode
  end


  -- Adjust last plan node normal given information about node to be inserted:
  -- The normal of the node that is currently the last in the plan may need to be updated
  -- either because the path has been extended (where previously it was the last node in the path)
  -- or because the path has changed from this node forwards
  if planCount > 1 then
    if plan[planCount].wayPointAhead ~= path[nextPathIdx] then
      local norm1 = plan[planCount].biNormal:cross(plan[planCount].posOrig - plan[planCount-1].posOrig)
      norm1:normalize()
      local norm2 = plan[planCount].biNormal:cross(n2Pos - plan[planCount].posOrig)
      norm2:normalize()
      plan[planCount].normal:setAdd2(norm1, norm2)
      local tmp = plan[planCount].normal:length()
      plan[planCount].normal:setScaled(1 / (tmp + 1e-30))
      plan[planCount].chordLength = (1 - norm1:dot(norm2) * 0.5) * tmp
    end
  else
    plan[planCount].normal:setSub2(n2Pos, plan[planCount].posOrig)
    plan[planCount].normal:setCross(plan[planCount].biNormal, plan[planCount].normal)
    plan[planCount].normal:normalize()
  end

  -- Calculate normal of node to be inserted into the plan
  -- This normal is calculated from the normals of the two path edges incident on it
  local nVec1 = vec3()
  if path[nextPathIdx-1] then
    nVec1:setSub2(n2Pos, mapData.positions[path[nextPathIdx-1]])
    nVec1:set(cross(n2biNormal, nVec1))
    nVec1:normalize()
  end

  local nVec2 = vec3()
  if wayPointAhead then
    nVec2:setSub2(mapData.positions[wayPointAhead], n2Pos)
    nVec2:set(cross(n2biNormal, nVec2))
    nVec2:normalize()
  end

  local n2Normal = nVec1 + nVec2
  local tmp = n2Normal:length()
  n2Normal:setScaled(1 / (tmp + 1e-30))
  local chordLength = (1 - nVec1:dot(nVec2) * 0.5) * tmp -- road width multiplier

  local lane = 0
  if driveInLaneFlag then
    lane = mapmgr.rules.rightHandDrive and -1 or 1

    if path[nextPathIdx-2] and path[nextPathIdx-1] and graph[path[nextPathIdx-2]][path[nextPathIdx-1]].inNode then
      -- currently two way roads only have one lane in each direction so if both the current and the next map segments are bidirectional there is no lane change decision to be made
      local minNode = roadNaturalContinuation(plan, path[nextPathIdx-2], path[nextPathIdx-1])
      local side = sign2(n2Pos:dot(plan[planCount].normal) - n1Pos:dot(plan[planCount].normal))
      if graph[path[nextPathIdx-1]][path[nextPathIdx]].inNode and minNode and minNode ~= nextNodeName and plan[planCount].lane * side < 0 then -- one way to one way lane change
        -- next node is not the natural continuation of last segment and current lane is in the wrong side
        plan[planCount].laneChange = true

        -- calculate length along plan up to the previous lane change
        local startNode
        local dist = 0
        for i = planCount-1, 1, -1 do
          if plan[i].laneChange then
            startNode = i
            break
          end
          dist = dist + plan[i].length
        end

        local newPos = plan[planCount].posOrig + (side * (0.5 * plan[planCount].radiusOrig * plan[planCount].chordLength)) * plan[planCount].normal
        local disp = plan[planCount].pos:distance(newPos)

        laneChange(plan, dist, side * disp, startNode, plan.planCount, true)
      elseif not graph[path[nextPathIdx-1]][path[nextPathIdx]].inNode and plan[planCount].lane * lane < 0 then -- one way to two way lane change
        plan[planCount].laneChange = true

        -- calculate length along plan up to the previous lane change
        local startNode
        local dist = 0
        for i = planCount-1, 1, -1 do
          if plan[i].laneChange then
            startNode = i
            break
          end
          dist = dist + plan[i].length
        end

        local newPos = plan[planCount].posOrig + (lane * (0.5 * plan[planCount].radiusOrig * plan[planCount].chordLength)) * plan[planCount].normal
        local disp = plan[planCount].pos:distance(newPos)

        laneChange(plan, dist, lane * disp, startNode, plan.planCount, true)
      end
    end

    if oneWay then
      if n2Radius > max(2.7, ai.width) then
        if planCount > 1 then
          if n1Radius < max(2.7, ai.width) then
            lane = sign(n2Normal:dot(n1Pos) - n2Normal:dot(n2Pos))
          else
            lane = plan[planCount].lane
            if lane == 0 then
              lane = sign(n2Normal:dot(n1Pos) - n2Normal:dot(n2Pos))
            end
          end
        elseif ai.currentSegment[1] and ai.currentSegment[2] and (path[1] == ai.currentSegment[1] or path[1] == ai.currentSegment[2]) then
          local fromWp, toWp
          if path[1] == ai.currentSegment[1] then
            if path[2] == ai.currentSegment[2] then
              fromWp, toWp = ai.currentSegment[1], ai.currentSegment[2]
            else
              fromWp, toWp = ai.currentSegment[2], ai.currentSegment[1]
            end
          elseif path[1] == ai.currentSegment[2] then
            if path[2] == ai.currentSegment[1] then
              fromWp, toWp = ai.currentSegment[2], ai.currentSegment[1]
            else
              fromWp, toWp = ai.currentSegment[1], ai.currentSegment[2]
            end
          end
          local pos1 = mapData.positions[toWp]
          local pos2 = mapData.positions[fromWp]
          local edgeMidPoint = (pos1 + pos2) * 0.5
          local edgeBinormal = mapmgr.surfaceNormalBelow(edgeMidPoint, ai.width * 0.5); edgeBinormal:setScaled(-1)
          local edgeNormal = edgeBinormal:cross(pos1 - pos2)
          lane = -sign(edgeNormal:dot(edgeMidPoint - aiPos))
        elseif path[2] then
          local curPathIdx = (plan[1] and plan[1].pathidx) and max(2, plan[1].pathidx) or 2
          local p1Pos = mapData.positions[path[curPathIdx-1]]
          lane = sign((mapData.positions[path[curPathIdx]] - p1Pos):z0():cross(gravityDir):dot(p1Pos - aiPos))
        end
      else
        lane = 0
      end
    end

    local width = max(n2Radius * 0.5, ai.width * 0.7)
    local displacement = max(0, n2Radius - width) -- provide a bit more space in narrow roads so other vehicles can overtake
    n2Pos:setAdd((displacement * lane * chordLength) * n2Normal)
    n2Radius = width
  end

  local lastPlanPos = plan[planCount] and plan[planCount].pos or aiPos
  local vec = lastPlanPos - n2Pos; vec.z = 0

  return {
    posOrig = vec3(mapData.positions[nextNodeName]),
    pos = n2Pos,
    vec = vec,
    dirVec = vec:normalized(),
    turnDir = vec3(0,0,0),
    biNormal = n2biNormal,
    normal = n2Normal,
    radius = n2Radius,
    radiusOrig = mapData.radius[nextNodeName],
    manSpeed = speedList and speedList[nextNodeName],
    pathidx = nextPathIdx,
    chordLength = chordLength,
    widthMarginOffset = 0,
    wayPointAhead = wayPointAhead,
    lane = lane,
    curvature = 0,
    oneWay = oneWay,
    lateralXnorm = nil,
    legalSpeed = nil,
    speed = nil
  }
end

local function mergePathPrefix(source, dest, srcStart)
  srcStart = srcStart or 1
  local sourceCount = #source
  local dict = table.new(0, sourceCount-(srcStart-1))
  for i = srcStart, sourceCount do
    dict[source[i]] = i
  end

  local destCount = #dest
  for i = destCount, 1, -1 do
    local srci = dict[dest[i]]
    if srci ~= nil then
      local res = table.new(destCount, 0)
      local resi = 1
      for i1 = srcStart, srci - 1 do
        res[resi] = source[i1]
        resi = resi + 1
      end
      for i1 = i, destCount do
        res[resi] = dest[i1]
        resi = resi + 1
      end

      return res, srci
    end
  end

  return dest, 0
end

local function uniformPlanErrorDistribution(plan)
  if threewayturn.state == 0 then
    local p1, p2 = plan[1].pos, plan[2].pos
    local dispVec = aiPos - linePointFromXnorm(p1, p2, aiPos:xnormOnLine(p1, p2)); dispVec:setScaled(min(1, 4 * dt))
    local dispVecDir = dispVec:normalized()

    local tmpVec = p2 - p1; tmpVec:setCross(tmpVec, ai.upVec); tmpVec:normalize()
    --aiDeviation = dispVec:dot(tmpVec)

    local j = 0
    local dTotal = 0
    for i = 1, plan.planCount-1 do
      tmpVec:setSub2(plan[i+1].pos, plan[i].pos)
      if math.abs(dispVecDir:dot(tmpVec)) > 0.5 * plan[i].length then
        break
      end
      j = i
      dTotal = dTotal + plan[i].length
    end

    local sumLen = 0
    for i = j, 1, -1 do
      local n = plan[i]
      sumLen = sumLen + plan[i].length

      local lateralXnorm = n.lateralXnorm or 0
      local newLateralXnorm = clamp(lateralXnorm + ((dispVec):dot(n.normal) * sumLen / dTotal), n.laneLimLeft or -math.huge, n.laneLimRight or math.huge)
      tmpVec:setScaled2(n.normal, newLateralXnorm - lateralXnorm)
      n.pos:setAdd(tmpVec)
      n.lateralXnorm = newLateralXnorm

      plan[i+1].vec:setSub2(plan[i].pos, plan[i+1].pos); plan[i+1].vec.z = 0
      plan[i+1].dirVec:setScaled2(plan[i+1].vec, 1 / plan[i+1].vec:lengthGuarded())
    end

    updatePlanLen(plan, 1, j)
  end
end

local function planAhead(route, baseRoute)
  if not route then return end

  if not route.path then
    route = {
      path = route,
      plan = table.new(15, 10)
    }
  end

  local plan = route.plan

  if baseRoute and not plan[1] then
    -- merge from base plan
    local bsrPlan = baseRoute.plan
    if bsrPlan[2] then
      local commonPathEnd
      route.path, commonPathEnd = mergePathPrefix(baseRoute.path, route.path, bsrPlan[2].pathidx)
      if commonPathEnd >= 1 then
        local refpathidx = bsrPlan[2].pathidx - 1
        local planLen, planCount = 0, 0
        for i = 1, #bsrPlan do
          local n = bsrPlan[i]
          if n.pathidx > commonPathEnd then break end
          planLen = planLen + (n.length or 0)
          planCount = i

          plan[i] = {
            posOrig = vec3(n.posOrig),
            pos = vec3(n.pos),
            vec = vec3(n.vec),
            dirVec = vec3(n.dirVec),
            turnDir = vec3(n.turnDir),
            biNormal = vec3(n.biNormal),
            normal = vec3(n.normal),
            radius = n.radius,
            radiusOrig = n.radiusOrig,
            pathidx = max(1, n.pathidx-refpathidx),
            roadSpeedLimit = n.roadSpeedLimit,
            chordLength = n.chordLength,
            widthMarginOffset = n.widthMarginOffset,
            wayPointAhead = n.wayPointAhead,
            lane = n.lane,
            length = n.length,
            curvature = n.curvature,
            lateralXnorm = n.lateralXnorm,
            legalSpeed = nil,
            speed = nil
          }
        end
        plan.planLen = planLen
        plan.planCount = planCount
        if plan[bsrPlan.targetSeg+1] then
          plan.targetSeg = bsrPlan.targetSeg
          plan.targetPos = vec3(bsrPlan.targetPos)
          plan.aiSeg = bsrPlan.aiSeg
        end
      end
    end
  end

  if not plan[1] then
    local vec = vec3(-8 * aiDirVec.x, -8 * aiDirVec.y, 0)
    plan[1] = {
      posOrig = vec3(aiPos),
      pos = vec3(aiPos),
      vec = vec,
      dirVec = vec:normalized(),
      turnDir = vec3(0,0,0),
      biNormal = -mapmgr.surfaceNormalBelow(aiPos, ai.width * 0.5),
      normal = vec3(),
      radiusOrig = 2,
      radius = 2,
      widthMarginOffset = 0,
      length = 0,
      curvature = 0,
      chordLength = 1,
      lateralXnorm = nil,
      pathidx = nil,
      roadSpeedLimit = nil,
      legalSpeed = nil,
      speed = nil
    }

    plan.planCount = 1
    plan.planLen = 0
  end

  local minPlanLen
  if M.mode == 'traffic' then
    minPlanLen = getMinPlanLen(40, aiSpeed, 0.2 * staticFrictionCoef)
  else
    minPlanLen = getMinPlanLen()
  end

  while not plan[MIN_PLAN_COUNT] or plan.planLen < minPlanLen do
    local n = buildNextRoute(plan, route.path)
    if not n then break end
    plan.planCount = plan.planCount + 1
    plan[plan.planCount] = n
    plan[plan.planCount-1].length = n.pos:distance(plan[plan.planCount-1].pos)
    plan.planLen = plan.planLen + plan[plan.planCount-1].length
  end

  if not plan[2] then return end
  if not plan[1].pathidx then
    plan[1].pathidx = plan[2].pathidx
    plan[1].roadSpeedLimit = plan[2].roadSpeedLimit
  end

  plan.segmentSplitDelay = plan.segmentSplitDelay or 0
  local distOnPlan = 0
  for i = 1, plan.planCount-1 do
    local curDist = plan[i].posOrig:squaredDistance(plan[i+1].posOrig)
    local xSq = square(distOnPlan)
    if curDist > square(min(220, (25e-8 * xSq + 1e-5) * xSq + 6)) and distOnPlan < 550 then
      if plan.segmentSplitDelay == 0 then
        local n1, n2 = plan[i], plan[i+1]

        local posOrig = n1.posOrig + n2.posOrig; posOrig:setScaled(0.5)
        local radiusOrig = (n1.radiusOrig + n2.radiusOrig) * 0.5

        local biNormal = mapmgr.surfaceNormalBelow(posOrig, radiusOrig * 0.5); biNormal:setScaled(-1)
        local normal = posOrig - plan[i].posOrig; normal:setCross(biNormal, normal); normal:normalize()

        local pos = n1.pos + n2.pos; pos:setScaled(0.5)
        local vec = n1.pos - pos; vec.z = 0
        local dirVec = vec:normalized()

        n1.length = n1.length * 0.5

        n2.vec:set(vec)
        n2.dirVec:set(dirVec)

        local roadSpeedLimit
        if n2.pathidx > 1 then
          roadSpeedLimit = mapData.graph[route.path[n2.pathidx]][route.path[n2.pathidx-1]].speedLimit
        else
          roadSpeedLimit = n2.roadSpeedLimit
        end

        local lane
        if n1.lane and n2.lane then
          if n2.pathidx > 1 then
            local oneWay = mapData.graph[route.path[n2.pathidx]][route.path[n2.pathidx-1]].inNode
            if oneWay and mapData.radius[route.path[n2.pathidx-1]] < 2.7 then
              lane = 0
            else
              lane = n2.lane
            end
          else
            lane = n2.lane
          end

          if not lane then lane = n2.lane end
        end

        if plan.stopSeg and plan.stopSeg >= i + 1 then
          plan.stopSeg = plan.stopSeg + 1
        end

        tableInsert(plan, i+1, {
          posOrig = posOrig,
          pos = pos,
          vec = vec,
          dirVec = dirVec,
          turnDir = vec3(0, 0, 0),
          biNormal = biNormal,
          normal = normal,
          radiusOrig = radiusOrig,
          radius = (n1.radius + n2.radius) * 0.5,
          pathidx = n2.pathidx,
          roadSpeedLimit = roadSpeedLimit,
          chordLength = 1,
          widthMarginOffset = (n1.widthMarginOffset + n2.widthMarginOffset) * 0.5,
          lane = lane,
          length = n1.length,
          curvature = 0,
          lateralXnorm = nil,
          legalSpeed = nil,
          speed = nil
        })

        plan.planCount = plan.planCount + 1
        plan.segmentSplitDelay = min(5, floor(90/aiSpeed))
      else
        plan.segmentSplitDelay = plan.segmentSplitDelay - 1
      end
      break
    end
    distOnPlan = distOnPlan + sqrt(curDist)
  end
  distOnPlan = nil

  if plan.targetSeg == nil then
    calculateTarget(plan)
  end

  for i = 0, plan.planCount do
    if forces[i] then
      forces[i]:set(0,0,0)
    else
      forces[i] = vec3(0,0,0)
    end
  end

  -- calculate spring forces
  local nforce = vec3()
  for i = 1, plan.planCount-1 do
    local n1 = plan[i]
    local v1 = n1.dirVec
    local v2 = plan[i+1].dirVec

    n1.turnDir:setSub2(v1, v2); n1.turnDir:normalize()
    nforce:setScaled2(n1.turnDir, (1-threewayturn.state) * max(1 - v1:dot(v2), 0) * parameters.turnForceCoef)

    forces[i+1]:setSub(nforce)
    forces[i-1]:setSub(nforce)
    nforce:setScaled(2)
    forces[i]:setAdd(nforce)
  end

  -- other vehicle awareness
  plan.trafficMinProjSpeed = math.huge

  table.clear(trafficTable)
  local trafficTableLen = 0

  for plID, v in pairs(mapmgr.getObjects()) do
    if plID ~= objectId and (M.mode ~= 'chase' or plID ~= player.id or chaseData.playerState == 'stopped') then
      v.targetType = (player and plID == player.id) and M.mode
      if avoidCars == 'on' or v.targetType == 'follow' then
        v.length = obj:getObjectInitialLength(plID) + 0.3
        v.width = obj:getObjectInitialWidth(plID)
        local posFront = obj:getObjectFrontPosition(plID)
        local dirVec = v.dirVec
        v.posFront = dirVec * 0.3 + posFront
        v.posRear = dirVec * (-v.length) + posFront
        v.posMiddle = (v.posFront + v.posRear) * 0.5

        table.insert(trafficTable, v)
        trafficTableLen = trafficTableLen + 1
      end
    end
  end

  if trafficTableLen > 0 then
    local trafficMinSpeedSq = math.huge
    local distanceT = 0
    local aiPathVel = ai.vel:dot(plan[2].pos - plan[1].pos) / (plan[1].length + 1e-30)
    local aiPathVelInv = 1 / abs(aiPathVel + 1e-30)
    local minTrafficDir = 1

    local sideDisp = 0
    local sideCoef = min(0.25, aiSpeed * 0.025)
    local sideVec = ai.rightVec * ai.width * 0.5
    local frontVec = aiDirVec * ai.length * 0.5 -- half length ahead
    local rearVec = -aiDirVec * ai.length * 2 -- half length behind
    local fl = aiPos - sideVec + frontVec
    local rl = fl + rearVec
    local fr = aiPos + sideVec + frontVec
    local rr = fr + rearVec

    for _, v in ipairs(trafficTable) do -- side avoidance loop
      if aiPos:squaredDistance(v.posFront) < square(ai.length) + square(ai.width + v.width) and aiSpeed > 1 and aiDirVec:dot(v.vel) > 0 then
        local rightVec = v.dirVec:cross(v.dirVecUp)

        local extSideVec = rightVec * (v.width * 0.5 + 0.3 + min(0.2, abs(v.dirVec:dot(plan[2].normal)))) -- half width, plus extra space
        local side1 = v.posMiddle - extSideVec
        local side2 = v.posMiddle + extSideVec

        local xnorm1, xnorm2 = closestLinePoints(side2, side2 - rightVec, rl, fl)
        local xnorm3, xnorm4 = closestLinePoints(side1, side1 + rightVec, rr, fr)
        local currSideDisp = 0

        if xnorm2 > 0 and xnorm2 < 1 and xnorm1 > 0 and xnorm1 < 1 then
          currSideDisp = (square(xnorm1 * 0.5) + xnorm1 * 0.1) * sideCoef -- displaces more sharply if vehicle sides are closer together
        elseif xnorm4 > 0 and xnorm4 < 1 and xnorm3 > 0 and xnorm3 < 1 then
          currSideDisp = (square(xnorm3 * 0.5) + xnorm3 * 0.1) * -sideCoef
        end

        sideDisp = sideDisp + currSideDisp
      end
    end

    if abs(sideDisp) > 0.01 then -- TODO: limit the side displacement to a calculated maximum
      --laneChange(plan, max(20, aiSpeed), sideDisp) -- not sure about the distance value

      -- doing the opposite plan movement of laneChange here
      local curDist = 0
      local lastPlanIdx = 2
      local targetDist = max(50, square(aiSpeed) / (2 * g * aggression))

      local tmpVec = vec3()
      for i = 2, plan.planCount - 1 do
        tmpVec:setScaled2(plan[i].normal, sideDisp * (targetDist - curDist) / targetDist)
        plan[i].pos:setAdd(tmpVec)
        plan[i].lane = 0
        curDist = curDist + plan[i - 1].length
        lastPlanIdx = i

        if curDist > targetDist then break end
      end

      for i = 2, lastPlanIdx do
        plan[i].vec:setSub2(plan[i-1].pos, plan[i].pos); plan[i].vec.z = 0
        plan[i].dirVec:set(plan[i].vec)
        plan[i].dirVec:normalize()
      end

      updatePlanLen(plan, 2, lastPlanIdx + 1)
    end

    local nDir, forceVec = vec3(), vec3()
    for i = 2, plan.planCount-1 do
      local n1, n2 = plan[i], plan[i+1]
      local n1pos, n2pos = n1.pos, n2.pos
      local n1n2len = n1.length
      nDir:setSub2(n2pos, n1pos); nDir:setScaled(1 / (n1n2len + 1e-30))
      n1.trafficSqVel = math.huge
      local arrivalT = distanceT * aiPathVelInv

      for j = trafficTableLen, 1, -1 do
        local v = trafficTable[j]
        local plPosFront, plPosRear, plWidth = v.posFront, v.posRear, v.width
        local ai2PlVec = plPosFront - aiPos
        local ai2PlDir = ai2PlVec:dot(aiDirVec)

        if ai2PlDir > 0 then
          local velDisp = arrivalT * v.vel
          plPosFront = plPosFront + velDisp
          plPosRear = plPosRear + velDisp
        end
        local extVec = nDir * (max(ai.width, plWidth) * 0.5)
        local n1ext, n2ext = n1pos - extVec, n2pos + extVec
        local rnorm, vnorm = closestLinePoints(n1ext, n2ext, plPosFront, plPosRear)

        local minSqDist = math.huge
        if rnorm > 0 and rnorm < 1 and vnorm > 0 and vnorm < 1 then
          minSqDist = 0
        else
          local rlen = n1n2len + plWidth
          local xnorm = plPosFront:xnormOnLine(n1ext, n2ext) * rlen
          local v1 = vec3()
          if xnorm > 0 and xnorm < rlen then
            v1:setScaled2(nDir, xnorm); v1:setAdd(n1ext)
            minSqDist = min(minSqDist, v1:squaredDistance(plPosFront))
          end

          xnorm = plPosRear:xnormOnLine(n1ext, n2ext) * rlen
          if xnorm > 0 and xnorm < rlen then
            v1:setScaled2(nDir, xnorm); v1:setAdd(n1ext)
            minSqDist = min(minSqDist, v1:squaredDistance(plPosRear))
          end

          rlen = v.length + ai.width
          v1:setSub2(n1ext, plPosRear)
          local v1dot = v1:dot(v.dirVec)
          if v1dot > 0 and v1dot < rlen then
            minSqDist = min(minSqDist, v1:squaredDistance(v1dot * v.dirVec))
          end

          v1:setSub2(n2ext, plPosRear)
          v1dot = v1:dot(v.dirVec)
          if v1dot > 0 and v1dot < rlen then
            minSqDist = min(minSqDist, v1:squaredDistance(v1dot * v.dirVec))
          end
        end

        local limWidth = v.targetType == 'follow' and 2 * max(n1.radiusOrig, n2.radiusOrig) or plWidth

        if minSqDist < square((ai.width + limWidth) * 0.8) then
          local velProjOnSeg = max(0, v.vel:dot(nDir))

          if not plan.stopSeg and v.targetType ~= 'follow' then -- apply side forces to avoid vehicles
            local side1 = sign(n1.normal:dot(v.posMiddle) - n1.normal:dot(n1.pos))
            local side2 = sign(n2.normal:dot(v.posMiddle) - n2.normal:dot(n2.pos))

            if not v.sideDir then
              v.sideDir = side1 -- save the avoidance direction once to compare it with all of the subsequent plan nodes
            end

            if v.sideDir == side1 then -- calculate force coef only if the avoidance side matches the initial value
              local forceCoef = trafficSide.side *
                                parameters.awarenessForceCoef *
                                max(0, aiSpeed - velProjOnSeg, -sign(nDir:dot(v.dirVec)) * trafficSide.cTimer) /
                                ((1 + minSqDist) * (1 + distanceT * min(0.1, 1 / (2 * max(0, aiPathVel - v.vel:dot(nDir)) + 1e-30))))

              forceVec:setScaled2(n1.normal, side1 * forceCoef)
              forces[i]:setSub(forceVec)

              forceVec:setScaled2(n1.normal, side2 * forceCoef)
              forces[i+1]:setSub(forceVec)
            end
          end

          if M.mode ~= 'flee' and M.mode ~= 'random' and not (M.mode == 'manual' and (2 * n1.radiusOrig / (abs(n1.lane or 0) + 1) - plWidth) > ai.width) then
            -- sets a minimum speed due to other vehicle velocity projection on plan segment
            -- only sets it if ai mode is valid; or if mode is "manual" but there is not enough space to pass

            if minSqDist < square((ai.width + limWidth) * 0.51)  then
              -- obj.debugDrawProxy:drawSphere(0.25, v.posFront, color(0,0,255,255))
              -- obj.debugDrawProxy:drawSphere(0.25, plPosFront, color(0,0,255,255))
              table.remove(trafficTable, j)
              trafficTableLen = trafficTableLen - 1
              plan.trafficMinProjSpeed = min(plan.trafficMinProjSpeed, velProjOnSeg)

              n1.trafficSqVel = min(n1.trafficSqVel, velProjOnSeg * velProjOnSeg)
              trafficMinSpeedSq = min(trafficMinSpeedSq, v.vel:squaredLength())
              minTrafficDir = min(minTrafficDir, v.dirVec:dot(nDir))
            end

            if i == 2 and minSqDist < square((ai.width + limWidth) * 0.6) and ai2PlDir > 0 and v.vel:dot(ai.rightVec) * ai2PlVec:dot(ai.rightVec) < 0 then
              n1.trafficSqVel = max(0, n1.trafficSqVel - abs(1 - v.vel:dot(aiDirVec)) * (v.vel:length()))
            end
          end
        end
      end
      distanceT = distanceT + n1n2len

      if trafficTableLen < 1 then
        break
      end
    end

    if intersection.timer < parameters.trafficWaitTime and plan.trafficMinProjSpeed < 3 then
      intersection.timer = 0 -- reset the intersection waiting timer
    end

    trafficBlock.block = max(trafficMinSpeedSq, aiSpeed*aiSpeed) < 1 and (minTrafficDir < -0.7 or intersection.block)

    plan[1].trafficSqVel = plan[2].trafficSqVel
  end

  -- spring force integrator

  local aiWidthMargin
  if trafficAction.forcedStop then
    aiWidthMargin = ai.width * 0.35
  else
    aiWidthMargin = ai.width * (0.35 + 0.3 / (1 + trafficSide.cTimer * 0.1)) + parameters.edgeDist
  end

  local tmpVec = vec3()
  for i = 2, plan.planCount do
    local n = plan[i]
    local roadHalfWidth = n.radiusOrig * n.chordLength
    n.roadHalfWidth = roadHalfWidth

    tmpVec:setAdd2(n.posOrig, n.normal)
    local lateralXnorm = clamp(n.pos:xnormOnLine(n.posOrig, tmpVec), -roadHalfWidth, roadHalfWidth)

    local k = n.normal:dot(forces[i])
    local displacement = fsign(k) * min(abs(k), 0.1) -- displacement distance per frame (lower value means better stability)
    local lane = n.lane or 0

    -- turn radius adjustment due to vehicle length
    if i < plan.planCount then
      local lengthScale = min(1, ai.length / 10)
      local turnRadius = max(ai.wheelBase, 1 / (n.curvature + 1e-30))
      local minTurnRadius = ai.wheelBase / math.tan(asin(ai.wheelBase / turnRadius)) -- expected minimum turning radius of rear of vehicle
      local turnRadiusDiff = min(roadHalfWidth * 0.5, turnRadius - minTurnRadius) * lengthScale -- difference between front and rear turning radii (with adjustment)
      turnRadiusDiff = turnRadiusDiff - max(0, n.radius * n.chordLength - aiWidthMargin) * 0.8 -- subtract extra space to side
      if turnRadiusDiff >= 0.1 then -- minimum turn difference
        -- lerp smoothing is done here to prevent plan instability and improve end of turning
        n.widthMarginOffset = lerp(n.widthMarginOffset, turnRadiusDiff * -sign(n.turnDir:dot(n.normal)), dt)
        -- apply width margin offset to neighboring nodes
        plan[i - 1].widthMarginOffset = lerp(plan[i - 1].widthMarginOffset, n.widthMarginOffset, min(0.8, lengthScale))
        plan[i + 1].widthMarginOffset = lerp(plan[i + 1].widthMarginOffset, n.widthMarginOffset, min(0.8, lengthScale))
      end
    end

    local roadLimLeft = -roadHalfWidth + aiWidthMargin
    local roadLimRight = roadHalfWidth - aiWidthMargin

    local laneLimLeft = roadLimLeft + max(0, roadHalfWidth * lane) + n.widthMarginOffset
    laneLimLeft = max(roadLimLeft, min(roadLimRight, laneLimLeft))
    n.laneLimLeft = laneLimLeft

    local laneLimRight = roadLimRight + min(0, roadHalfWidth * lane) + n.widthMarginOffset
    laneLimRight = max(roadLimLeft, min(roadLimRight, laneLimRight))
    n.laneLimRight = laneLimRight

    local newLateralXnorm = clamp(lateralXnorm + displacement, laneLimLeft, laneLimRight)

    -- temporal non linear filter
    --local lateralXnormRateDt = 10 * dt
    --local alpha = lateralXnormRateDt / (lateralXnormRateDt + 1)
    --newLateralXnorm = (1 - alpha) * lateralXnorm + alpha * newLateralXnorm

    -- n.limLeft, n.limRight = limLeft, limRight -- uncomment to debug lane limits
    tmpVec:setScaled2(n.normal, newLateralXnorm - lateralXnorm)
    n.pos:setAdd(tmpVec) -- remember that posOrig and pos are not alligned along the normal
    n.vec:setSub2(plan[i-1].pos, n.pos); n.vec.z = 0
    n.dirVec:set(n.vec); n.dirVec:normalize()

    n.lateralXnorm = newLateralXnorm
    n.radius = max(0, n.radiusOrig * n.chordLength - abs(newLateralXnorm))
  end
  updatePlanLen(plan, 2, plan.planCount)

  -- smoothly distribute error from planline onto the front segments
  if plan.targetPos and plan.targetSeg and plan.planCount > plan.targetSeg and threewayturn.state == 0 then
    local dTotal = 0
    local sumLen = table.new(plan.targetSeg-1, 0)
    sumLen[1] = 0
    for i = 2, plan.targetSeg - 1  do
      sumLen[i] = dTotal
      dTotal = dTotal + plan[i].length
    end
    dTotal = max(1, dTotal + plan.targetPos:distance(plan[plan.targetSeg].pos))

    local p1, p2 = plan[1].pos, plan[2].pos
    local dispVec = aiPos - linePointFromXnorm(p1, p2, aiPos:xnormOnLine(p1, p2)); dispVec:setScaled(0.5 * dt)

    tmpVec:setSub2(p2, p1); tmpVec:setCross(tmpVec, ai.upVec); tmpVec:normalize()
    aiDeviation = dispVec:dot(tmpVec)

    local dispVecRatio = dispVec / dTotal
    for i = plan.targetSeg - 1, 1, -1 do
      local n = plan[i]

      dispVec:setScaled2(dispVecRatio, dTotal - sumLen[i])
      n.pos:setAdd(dispVec)

      local halfWidth = n.radiusOrig * n.chordLength
      tmpVec:setAdd2(n.posOrig, n.normal)
      n.lateralXnorm = clamp(n.pos:xnormOnLine(n.posOrig, tmpVec), -halfWidth, halfWidth)

      plan[i+1].vec:setSub2(plan[i].pos, plan[i+1].pos); plan[i+1].vec.z = 0
      plan[i+1].dirVec:setScaled2(plan[i+1].vec, 1 / plan[i+1].vec:lengthGuarded())
    end

    updatePlanLen(plan, 1, plan.targetSeg-1)
  end

  calculateTarget(plan)

  -- Speed Planning --

  local totalAccel = min(aggression, staticFrictionCoef) * g

  local rLast = plan[plan.planCount]
  if route.path[rLast.pathidx+1] or (race and noOfLaps and noOfLaps > 1) then
    if plan.stopSeg and plan.stopSeg <= plan.planCount then
      rLast.speed = 0
    else
      rLast.speed = rLast.manSpeed or sqrt(2 * 550 * totalAccel) -- shouldn't this be calculated based on the path length remaining?
    end
  else
    rLast.speed = rLast.manSpeed or 0
  end
  rLast.roadSpeedLimit = plan[plan.planCount-1].roadSpeedLimit
  rLast.legalSpeed = min(rLast.roadSpeedLimit or math.huge, rLast.speed)

  local len, n1Vec, n2Vec, n3vec = 0, vec3(plan[1].vec), vec3(plan[2].vec), vec3()
  plan[1].curvature = plan[1].curvature or inCurvature(n1Vec, n2Vec)
  for i = 2, plan.planCount - 1 do
    local n1 = plan[i]

    n1Vec:set(n1.vec)
    n2Vec:set(plan[i+1].vec)
    local curvature = inCurvature(n1Vec, n2Vec)

    n1Vec:set(n1.vec)
    n3vec:setSub2(n1.pos, plan[min(plan.planCount, i + 2)].pos); n3vec.z = 0
    curvature = min(curvature, inCurvature(n1Vec, n3vec))

    local curvatureRateDt = min(25 + 0.000045 * len * len * len * len, 1000) * dt
    local alpha = curvatureRateDt / (1 + curvatureRateDt)
    n1.curvature = n1.curvature and (alpha * n1.curvature + (1 - alpha) * curvature) or curvature -- fast reacting -- time dependent

    len = len + n1.length
  end

  local gT = vec3()
  for i = plan.planCount-1, 1, -1 do
    local n1 = plan[i]
    local n2 = plan[i+1]

    -- consider inclination
    gT:setSub2(n2.pos, n1.pos); gT:setScaled2(gT, gravityVec:dot(gT) / max(n1.length, 1e-30)) -- gravity vec parallel to road segment: positive when downhill
    local gN = gravityVec:distance(gT) / g -- gravity component normal to road segment

    local curvature = max(n1.curvature, 1e-5)
    local turnSpeedSq = totalAccel * gN / curvature -- available centripetal acceleration * radius

    -- https://physics.stackexchange.com/questions/312569/non-uniform-circular-motion-velocity-optimization
    local n2SpeedSq = square(n2.speed)
    local n1SpeedSq = turnSpeedSq * sin(min(asin(min(1, n2SpeedSq / turnSpeedSq)) + 2 * curvature * n1.length, pi * 0.5))
    n1SpeedSq = min(n1SpeedSq, n1.trafficSqVel or math.huge, plan.stopSeg and plan.stopSeg <= i and 0 or math.huge)

    n1.speed = n1.manSpeed or
              (M.speedMode == 'limit' and M.routeSpeed and min(M.routeSpeed, sqrt(n1SpeedSq))) or
              (M.speedMode == 'set' and M.routeSpeed) or
              sqrt(n1SpeedSq)

    if M.speedMode == 'legal' then
      n2.legalSpeed = n2.legalSpeed or n2.speed
      local n2LegalSpeedSq = square(n2.legalSpeed)
      local n1LegalSpeedSq = turnSpeedSq * sin(min(asin(min(1, n2LegalSpeedSq / turnSpeedSq)) + 2 * curvature * n1.length, pi * 0.5))
      n1LegalSpeedSq = min(n1LegalSpeedSq, n1.trafficSqVel or math.huge, plan.stopSeg and plan.stopSeg <= i and 0 or math.huge)
      local roadSpeedLimit = n1.roadSpeedLimit and n1.roadSpeedLimit * (1 + (aggression * 2 - 0.6)) or math.huge -- may drive a bit faster or slower than the actual limit
      n1.legalSpeed = min(roadSpeedLimit, sqrt(n1LegalSpeedSq))
    end

    n1.trafficSqVel = math.huge
  end

  plan.targetSpeed = plan[1].speed + max(0, plan.aiXnormOnSeg) * (plan[2].speed - plan[1].speed)
  if M.speedMode == 'legal' then
    plan.targetSpeedLegal = plan[1].legalSpeed + max(0, plan.aiXnormOnSeg) * (plan[2].legalSpeed - plan[1].legalSpeed)
  else
    plan.targetSpeedLegal = math.huge
  end

  return route
end

local function resetMapAndRoute()
  mapData = nil
  signalsData = nil
  currentRoute = nil
  race = nil
  noOfLaps = nil
  internalState = 'onroad'
  changePlanTimer = 0
  resetAggression()
  resetTrafficTables()
  resetParameters()
end

local function getMapEdges(cutOffDrivability, node)
  -- creates a table (edgeDict) with map edges with drivability > cutOffDrivability
  if mapData ~= nil then
    local allSCC = mapData:scc(node) -- An array of dicts containing all strongly connected components reachable from 'node'.
    local maxSccLen = 0
    local sccIdx
    for i, scc in ipairs(allSCC) do
      -- finds the scc with the most nodes
      local sccLen = scc[0] -- position at which the number of nodes in currentSCC is stored
      if sccLen > maxSccLen then
        sccIdx = i
        maxSccLen = sccLen
      end
      scc[0] = nil
    end
    local currentSCC = allSCC[sccIdx]
    local keySet = {}
    local keySetLen = 0

    edgeDict = {}
    for nid, n in pairs(mapData.graph) do
      if currentSCC[nid] or not driveInLaneFlag then
        for lid, data in pairs(n) do
          if (currentSCC[lid] or not driveInLaneFlag) and (data.drivability > cutOffDrivability) then
            local inNode = data.inNode or nid
            local outNode = inNode == nid and lid or nid
            keySetLen = keySetLen + 1
            keySet[keySetLen] = {inNode, outNode}
            edgeDict[inNode..'\0'..outNode] = 1
            if not data.inNode or not driveInLaneFlag then
              edgeDict[outNode..'\0'..inNode] = 1
            end
          end
        end
      end
    end

    if keySetLen == 0 then return end
    local edge = keySet[math.random(keySetLen)]

    return edge[1], edge[2]
  end
end

local function newManualPath()
  local newRoute, n1, n2, dist
  local offRoad = false

  if manualPath then
    if currentRoute and currentRoute.path then
      pathExtend(currentRoute.path, manualPath)
    else
      newRoute = {plan = {}, path = manualPath}
      currentRoute = newRoute
    end
    manualPath = nil
  elseif wpList then
    if currentRoute and currentRoute.path then
      newRoute = {plan = currentRoute.plan, path = currentRoute.path}
    else
      n1, n2, dist = mapmgr.findClosestRoad(aiPos)

      if n1 == nil or n2 == nil then
        guihooks.message("Could not find a road network, or closest road is too far", 5, "AI debug")
        log('D', "AI", "Could not find a road network, or closest road is too far")
        return
      end

      ai.currentSegment[1] = n1
      ai.currentSegment[2] = n2

      if dist > 2 * max(mapData.radius[n1], mapData.radius[n2]) then
        offRoad = true
        local vec1 = mapData.positions[n1] - aiPos
        local vec2 = mapData.positions[n2] - aiPos

        if aiDirVec:dot(vec1) > 0 and aiDirVec:dot(vec2) > 0 then
          if vec1:squaredLength() > vec2:squaredLength() then
            n1, n2 = n2, n1
          end
        elseif aiDirVec:dot(mapData.positions[n2] - mapData.positions[n1]) > 0 then
          n1, n2 = n2, n1
        end
      elseif aiDirVec:dot(mapData.positions[n2] - mapData.positions[n1]) > 0 then
        n1, n2 = n2, n1
      end

      newRoute = {plan = {}, path = {n1}}
    end

    for i = 0, #wpList-1 do
      local wp1 = wpList[i] or newRoute.path[#newRoute.path]
      local wp2 = wpList[i+1]
      local route = mapData:getPath(wp1, wp2, driveInLaneFlag and 1e4 or 1)
      local routeLen = #route
      if routeLen == 0 or (routeLen == 1 and wp2 ~= wp1) then
        guihooks.message("Path between waypoints '".. wp1 .."' - '".. wp2 .."' Not Found", 7, "AI debug")
        log('D', "AI", "Path between waypoints '".. wp1 .."' - '".. wp2 .."' Not Found")
        return
      end

      for j = 2, routeLen do
        tableInsert(newRoute.path, route[j])
      end
    end

    wpList = nil

    if not offRoad and newRoute.path[3] and newRoute.path[2] == n2 then
      tableRemove(newRoute.path, 1)
    end

    currentRoute = newRoute
  end
end

local function validateUserInput(list)
  validateInput = nop
  list = list or wpList
  if not list then return end
  local isValid = list[1] and true or false
  for i = 1, #list do -- #wpList
    local nodeAlias = mapmgr.nodeAliases[list[i]]
    if nodeAlias then
      if mapData.graph[nodeAlias] then
        list[i] = nodeAlias
      else
        if isValid then
          guihooks.message("One or more of the waypoints were not found on the map. Check the game console for more info.", 6, "AI debug")
          log('D', "AI", "The waypoints with the following names could not be found on the Map")
          isValid = false
        end
        -- print(list[i])
      end
    end
  end

  return isValid
end

local function fleePlan()
  if aggressionMode == 'rubberBand' then
    setAggressionInternal(max(0.3, 0.95 - 0.0015 * player.pos:distance(aiPos)))
  end

  -- extend the plan if possible and desirable
  if currentRoute and not currentRoute.plan.reRoute then
    local plan = currentRoute.plan
    if (aiPos - player.pos):dot(aiDirVec) >= 0 and not targetWPName and internalState ~= 'offroad' and plan.trafficMinProjSpeed > 3 then
      local path = currentRoute.path
      local pathCount = #path
      if pathCount >= 3 and plan[2].pathidx > pathCount * 0.7 then
        local cr1 = path[pathCount-1]
        local cr2 = path[pathCount]
        local dirVec = mapData.positions[cr2] - mapData.positions[cr1]
        dirVec:normalize()
        pathExtend(path, mapData:getFleePath(cr2, dirVec, player.pos, getMinPlanLen(), 0.01, 0.01))
        planAhead(currentRoute)
        return
      end
    end
  end

  if not currentRoute or changePlanTimer == 0 or currentRoute.plan.reRoute then
    local wp1, wp2 = mapmgr.findClosestRoad(aiPos)
    if wp1 == nil or wp2 == nil then
      internalState = 'offroad'
      return
    else
      internalState = 'onroad'
    end

    ai.currentSegment[1] = wp1
    ai.currentSegment[2] = wp2

    local dirVec
    if currentRoute and currentRoute.plan.trafficMinProjSpeed < 3 then
      changePlanTimer = 5
      dirVec = -aiDirVec
    else
      dirVec = aiDirVec
    end

    local startnode = pickAiWp(wp1, wp2, dirVec)
    local path
    if not targetWPName then
      path = mapData:getFleePath(startnode, dirVec, player.pos, getMinPlanLen(), 0.01, 0.01)
    else -- flee to destination
      path = mapData:getPathAwayFrom(startnode, targetWPName, aiPos, player.pos)
      if next(path) == nil then
        targetWPName = nil
      end
    end

    if not path[1] then
      internalState = 'offroad'
      return
    else
      internalState = 'onroad'
    end

    local route = planAhead(path, currentRoute)
    if route and route.plan then
      local tempPlan = route.plan
      if not currentRoute or changePlanTimer > 0 or tempPlan.targetSpeed >= min(aiSpeed, currentRoute.plan.targetSpeed) and targetsCompatible(currentRoute, route) then
        currentRoute = route
        changePlanTimer = max(1, changePlanTimer)
        return
      elseif currentRoute.plan.reRoute then
        currentRoute = route
        changePlanTimer = max(1, changePlanTimer)
        return
      end
    end
  end

  planAhead(currentRoute)
end

local function chasePlan()
  local positions = mapData.positions
  local radii = mapData.radius

  local wp1, wp2, dist1 = mapmgr.findClosestRoad(aiPos)
  if wp1 == nil or wp2 == nil then
    internalState = 'offroad'
    return
  end

  local plwp1, plwp2, dist2 = mapmgr.findClosestRoad(player.pos)
  if plwp1 == nil or plwp2 == nil then
    internalState = 'offroad'
    return
  end

  if aiDirVec:dot(positions[wp2] - positions[wp1]) < 0 then wp1, wp2 = wp2, wp1 end
  -- wp2 is next node for ai to drive to

  ai.currentSegment[1] = wp1
  ai.currentSegment[2] = wp2

  local playerSpeed = player.vel:length()
  local playerVel = playerSpeed > 1 and player.vel or player.dirVec -- uses dirVec for very low speeds
  if (playerVel / (playerSpeed + 1e-30)):dot(positions[plwp2] - positions[plwp1]) < 0 then plwp1, plwp2 = plwp2, plwp1 end
  -- plwp2 is next node that player is driving to

  if dist1 > max(radii[wp1], radii[wp2]) + ai.width and dist2 > max(radii[plwp1], radii[plwp2]) + obj:getObjectInitialWidth(player.id) then
    internalState = 'offroad'
    return
  end

  local playerNode = plwp2
  local aiPlDist = aiPos:distance(player.pos) -- should this be a signed distance?
  local aiPosRear = aiPos - aiDirVec * ai.length
  local nearDist = ai.length + 8
  local isAtPlayerSeg = (wp1 == playerNode or wp2 == playerNode)

  if aggressionMode == 'rubberBand' then
    if M.mode == 'follow' then
      setAggressionInternal(min(0.75, 0.3 + 0.0025 * aiPlDist))
    else
      setAggressionInternal(min(0.95, 0.8 + 0.0015 * aiPlDist))
    end
  end

  -- consider calculating the aggression value but then passing it through a smoother so that transitions between chase mode and follow mode are smooth

  if playerSpeed < 1 then
    chaseData.playerStoppedTimer = chaseData.playerStoppedTimer + dt
  else
    chaseData.playerStoppedTimer = 0
  end

  if chaseData.playerStoppedTimer > 5 and aiPlDist <= max(nearDist, square(aiSpeed) / (2 * g * aggression)) then -- within braking distance to player
    chaseData.playerState = 'stopped'

    if aiSpeed < 0.3 and aiPlDist < nearDist then
      -- do not plan new route if stopped near player
      currentRoute = nil
      internalState = 'onroad'
      return
    end
  else
    chaseData.playerState = nil
  end

  if M.mode == 'follow' and aiSpeed < 0.3 and isAtPlayerSeg and aiPlDist < nearDist then
    -- do not plan new route if ai reached player
    currentRoute = nil
    internalState = 'onroad'
    return
  end

  if currentRoute then
    local curPlan = currentRoute.plan
    local playerNodeInPath = waypointInPath(currentRoute.path, playerNode, curPlan[2].pathidx) or false

    local planVec = curPlan[2].pos - curPlan[1].pos
    local playerIncoming = playerNode == wp1 and aiPlDist < max(aiSpeed, playerSpeed) and playerVel:dot(planVec) < 0 -- player is driving towards or past ai on the ai segment
    local playerBehind = playerNodeInPath and playerNodeInPath <= curPlan[2].pathidx and planVec:dot(playerVel) > 0 and (aiPosRear - player.pos):dot(aiDirVec) > 0 -- player got passed by ai
    local playerOtherWay = not playerNodeInPath and playerVel:dot(player.pos - aiPos) > 0 and planVec:dot(positions[playerNode] - aiPos) < 0 -- player is driving other way from ai

    local keepRoute = aiSpeed >= 3 and (playerIncoming or playerBehind or playerOtherWay) -- keeps the current route until the ai vehicle stops to turn around

    local route
    if not keepRoute and not playerNodeInPath then
      local path = mapData:getChasePath(wp1, wp2, plwp1, plwp2, aiPos, ai.vel, player.pos, player.vel, driveInLaneFlag and 1e4 or 1)

      route = planAhead(path, currentRoute) -- ignore current route if path should go other way
      if route and route.plan then --and tempPlan.targetSpeed >= min(aiSpeed, curPlan.targetSpeed) and (tempPlan.targetPos-curPlan.targetPos):dot(aiDirVec) >= 0 then
        currentRoute = route
      end
    end

    local pathLen = getPathLen(currentRoute.path, playerNodeInPath or math.huge) -- curPlan[2].pathidx
    local playerMinPlanLen = getMinPlanLen(0, playerSpeed, 0.5 * staticFrictionCoef)
    if M.mode == 'chase' and pathLen < playerMinPlanLen and not keepRoute then -- ai chase path should be extended
      local pathCount = #currentRoute.path
      local fleePath = mapData:getFleePath(currentRoute.path[pathCount], playerVel, player.pos, playerMinPlanLen, 0, 0)
      if fleePath[2] ~= wp1 and fleePath[2] ~= wp2 and fleePath[2] ~= currentRoute.path[pathCount - 1] then -- only extend the path if it does not do a u-turn
        pathExtend(currentRoute.path, fleePath)
      end
    end

    if not route then
      planAhead(currentRoute)

      if keepRoute then
        local targetSpeed = max(0, aiSpeed - sqrt(max(0, square(staticFrictionCoef * g) - square(sensors.gx2))) * dt) -- brake to a stop
        curPlan.targetSpeed = min(curPlan.targetSpeed, targetSpeed)
      end
    end

    if M.mode == 'chase' and (plwp2 == currentRoute.path[curPlan[2].pathidx] or plwp2 == currentRoute.path[curPlan[2].pathidx + 1]) then
      local playerNodePos1 = positions[plwp2]
      local segDir = playerNodePos1 - positions[plwp1]
      local targetLineDir = vec3(-segDir.y, segDir.x, 0); targetLineDir:normalize()
      local xnorm1 = closestLinePoints(playerNodePos1, playerNodePos1 + targetLineDir, player.pos, player.pos + player.dirVec)
      local xnorm2 = closestLinePoints(playerNodePos1, playerNodePos1 + targetLineDir, aiPos, aiPos + aiDirVec)
      -- player xnorm and ai xnorm get interpolated here
      local tarPos = playerNodePos1 + targetLineDir * clamp(lerp(xnorm1, xnorm2, 0.5), -radii[plwp2], radii[plwp2])

      local p2Target = tarPos - player.pos; p2Target:normalize()
      local plVel2Target = playerSpeed > 0.1 and player.vel:dot(p2Target) or 0
      --local plAccel = (plVel2Target - plPrevVel:dot(p2Target)) / dt
      --plAccel = plAccel + sign2(plAccel) * 1e-5
      --local plTimeToTarget = (sqrt(max(plVel2Target * plVel2Target + 2 * plAccel * (tarPos - player.pos):length(), 0)) - plVel2Target) / plAccel
      local plTimeToTarget = tarPos:distance(player.pos) / (plVel2Target + 1e-30) -- accel maybe not needed; this gives smooth results

      local aiVel2Target = aiSpeed > 0.1 and ai.vel:dot((tarPos - aiPos):normalized()) or 0
      local aiTimeToTarget = tarPos:distance(aiPos) / (aiVel2Target + 1e-30)

      if aiTimeToTarget < plTimeToTarget and not playerBehind then
        internalState = 'tail'
      else
        internalState = 'onroad'
      end
    else
      if M.mode == 'chase' and playerIncoming and playerVel:dot(player.pos - aiPos) < 0 then
        internalState = 'tail'
      else
        internalState = 'onroad'
      end
    end

    if chaseData.playerState == 'stopped' then
      currentRoute.plan.targetSpeed = 0
    end
  else
    local path = mapData:getChasePath(wp1, wp2, plwp1, plwp2, aiPos, ai.vel, player.pos, player.vel, driveInLaneFlag and 1e4 or 1)

    local route = planAhead(path)
    if route and route.plan then
      currentRoute = route
    end
  end
end

local function trafficActions()
  local path, plan = currentRoute.path, currentRoute.plan
  local brakeDist = square(aiSpeed) / (2 * g * aggression)

  -- horn
  if parameters.enableElectrics and trafficAction.hornTimer == 0 then
    electrics.horn(true)
    trafficAction.hornTimerLimit = max(0.1, math.random())
  end
  if trafficAction.hornTimer >= trafficAction.hornTimerLimit then
    electrics.horn(false)
    trafficAction.hornTimer = -1
  end

  if trafficAction.hornTimer >= 0 then
    trafficAction.hornTimer = trafficAction.hornTimer + dt
  end

  local pullOver = false

  -- hazard lights
  if beamstate.damage >= 1000 then
    if electrics.values.signal_left_input == 0 and electrics.values.signal_right_input == 0 then
      electrics.set_warn_signal(1)
    end
    pullOver = true
  end

  -- pull over
  local minSirenSqDist = math.huge

  mapmgr.getObjects()
  for plID, v in pairs(mapmgr.objects) do
    if plID ~= objectId and v.states and v.states.lightbar then
      local posFront = obj:getObjectFrontPosition(plID)
      minSirenSqDist = min(minSirenSqDist, posFront:squaredDistance(aiPos))
    end
  end
  if minSirenSqDist <= 10000 then
    pullOver = true
  end

  if pullOver and not trafficAction.forcedStop then
    local dist = max(10, brakeDist)
    local idx = planSegAtDist(plan, dist)
    local n = plan[idx]
    local side = mapmgr.rules.rightHandDrive and -1 or 1
    local disp = n.pos:distance(n.posOrig + n.normal * side * (n.radiusOrig * n.chordLength - ai.width * 0.5))
    trafficSide.displacement = disp
    dist = dist + disp * 4 -- extra distance if vehicle has more displacement to cover

    laneChange(plan, max(5, dist - 20), disp * side)
    setStopPoint(plan, dist)
    trafficAction.forcedStop = true
    trafficSide.side = mapmgr.rules.rightHandDrive and -1 or 1
  end

  if not pullOver and trafficAction.forcedStop then
    laneChange(plan, 40, -trafficSide.displacement) -- resets lane
    setStopPoint()
    trafficAction.forcedStop = false
  end

  if trafficAction.forcedStop and aiSpeed < min(plan.targetSpeed or 0, 1) then -- instant plan stop
    setStopPoint(plan, 0)
  end

  -- intersections & turn signals
  if not intersection.node then
    local dist = aiPos:distance(mapData.positions[path[plan[1].pathidx]])
    local minLen = getMinPlanLen(100) -- limit the distance to look ahead for intersections
    local tempData = {}
    intersection.block = false

    for i = plan[1].pathidx, #path - 1 do
      if intersection.prevNode == path[i] or dist > minLen then break end -- vehicle is still within previous intersection, or distance is too far

      local nid1, nid2 = path[i], path[i + 1]
      local n1Pos, n2Pos = mapData.positions[nid1], mapData.positions[nid2]
      local prevNode = i > 1 and path[i - 1] -- use previous path node if it exists
      local nDir = prevNode and (n1Pos - mapData.positions[prevNode]):normalized() or aiDirVec

      if not tempData.node and signalsData then -- defined intersections
        local sNodes = signalsData.nodes
        if sNodes[nid1] then -- node from current path was found in the signals dict
          for i, node in ipairs(sNodes[nid1]) do
            if nDir:dot(node.dir) > 0.9 then -- if signal direction is valid
              -- insert lane check here if applicable
              tempData = {node = nid1, nextNode = nid2, nodeIdx = i, pos = node.pos, dir = node.dir, action = 1}
            end
          end
        end
      end

      if not tempData.turnDir and tableSize(mapData.graph[nid1]) > 2 then -- auto intersections
        -- we should try to get the effective curvature of the path after this point to determine turn signals
        local linkDir = (n2Pos - n1Pos):z0(); linkDir:normalize()
        local drivability = prevNode and mapData.graph[nid1][prevNode].drivability or 1
        local linkMainRoad = false

        if drivability < 1 then
          for _, edgeData in pairs(mapData.graph[nid1]) do
            if edgeData.drivability > drivability then
              linkMainRoad = true
              break
            end
          end
        end

        if abs(nDir:dot(linkDir)) < 0.7 or linkMainRoad then -- junction turn or drivability difference
          if not tempData.node then
            local pos = n1Pos - nDir * (max(3, mapData.radius[nid1]) + 2)
            tempData = {node = nid1, nextNode = nid2, turnNode = nid1, dir = nDir, turnDir = linkDir, pos = pos, action = 0.1}
          else
            tempData.turnNode = nid1
            tempData.turnDir = linkDir
          end
        end
      end

      if tempData.node then
        intersection = tableMerge(intersection, tempData) -- fill intersection table and continue
        if intersection.turnDir and abs(intersection.dir:dot(intersection.turnDir)) < 0.7 then
          intersection.turn = -sign2(intersection.dir:cross(gravityDir):dot(intersection.turnDir)) -- turn detection
        end
        break
      end

      dist = dist + n1Pos:distance(n2Pos)
    end
  else
    if not trafficAction.forcedStop then
      local signalsRef = intersection.nodeIdx and signalsData.nodes[intersection.node][intersection.nodeIdx]
      if signalsRef then
        intersection.action = signalsRef.action or 1 -- get action from referenced table
      else
        intersection.action = intersection.action or 1 -- default action ("go")
      end

      --local sColor = (intersection.action and intersection.action <= 0.1) and color(255,0,0,160) or color(0,255,0,160)
      --obj.debugDrawProxy:drawSphere(1, intersection.pos, sColor)
      --obj.debugDrawProxy:drawText(intersection.pos + vec3(0, 0, 1), color(0,0,0,255), tostring(intersection.turn))

      local stopSeg
      local bestDist = math.huge
      local distSq = aiPos:squaredDistance(intersection.pos)
      local turnValue = mapmgr.rules.rightHandDrive and -1 or 1 -- curb turn is left or right depending on RHD

      if ((intersection.pos + intersection.dir * 4) - aiPos):dot(intersection.dir) >= 0 then -- vehicle position is at the stop pos (with extra distance, to be safe)
        if intersection.action <= 0.1 or (intersection.action == 0.5 and square(brakeDist) < distSq) then -- red light or other stop condition
          for i = 1, #plan - 1 do -- get best plan node to set as a stopping point
            -- currently checks every frame due to plan segment updates
            local dist = plan[i].pos:squaredDistance(intersection.pos)
            if dist < bestDist then
              bestDist = dist
              stopSeg = i
            end
          end
          intersection.block = false
        else
          intersection.block = aiSpeed <= 1 and distSq <= 400 and intersection.turn ~= -turnValue -- blocked at green light and not a left turn
        end

        if intersection.action <= 0.1 then
          if stopSeg and stopSeg <= 2 and aiSpeed <= 1 then -- stopped at stopping point
            intersection.timer = intersection.timer + dt
          end
          if intersection.timer >= parameters.trafficWaitTime then
            if intersection.action == 0 then
              if mapmgr.rules.turnOnRed and intersection.turn == turnValue then -- right turn on red allowed
                intersection.nodeIdx = nil
                intersection.action = 1
              end
            else
              intersection.nodeIdx = nil
              intersection.action = 1
            end
          end
        end
      else
        intersection = {timer = 0, turn = 0, block = false, prevNode = intersection.node} -- after this is reset, the next intersection can be searched for
      end

      plan.stopSeg = stopSeg
    end

    if parameters.enableElectrics and intersection.turnNode and aiPos:squaredDistance(mapData.positions[intersection.turnNode]) < square(max(20, brakeDist * 1.2)) then -- approaching intersection
      if intersection.turn < 0 and electrics.values.turnsignal >= 0 then
        electrics.toggle_left_signal()
      elseif intersection.turn > 0 and electrics.values.turnsignal <= 0 then
        electrics.toggle_right_signal()
      end
    end
  end
end

local function trafficPlan()
  if trafficBlock.block then
    trafficBlock.timer = trafficBlock.timer + dt
  else
    trafficBlock.timer = trafficBlock.timer * 0.8
    trafficBlock.hornFlag = false
  end

  if currentRoute and currentRoute.path[3] and not currentRoute.plan.reRoute and trafficBlock.timer <= trafficBlock.timerLimit then
    local plan = currentRoute.plan
    local path = currentRoute.path
    if internalState ~= 'offroad' and plan.planLen + getPathLen(path, plan[plan.planCount].pathidx) < getMinPlanLen() then -- and path[3]
      local pathCount = #path
      local positions = mapData.positions
      local cr0, cr1, cr2 = path[pathCount-2], path[pathCount-1], path[pathCount]
      local cr2Pos = positions[cr2]
      local dir1 = cr2Pos - positions[cr1]; dir1:normalize()
      local vec = cr2Pos - positions[cr0]
      local mirrorOfVecAboutdir1 = 2 * vec:dot(dir1) * dir1 - vec; mirrorOfVecAboutdir1:normalize()
      pathExtend(path, mapData:getPathT(cr2, cr2Pos, getMinPlanLen(), 1e4, mirrorOfVecAboutdir1))
      trafficActions()
      planAhead(currentRoute)
      return
    end
  else
    local wp1, wp2 = mapmgr.findClosestRoad(aiPos)

    if wp1 == nil or wp2 == nil then
      guihooks.message("Could not find a road network, or closest road is too far", 5, "AI debug")
      currentRoute = nil
      internalState = 'offroad'
      changePlanTimer = 0
      driveCar(0, 0, 0, 1)
      return
    end

    local radius = mapData.radius
    local position = mapData.positions
    local graph = mapData.graph

    local dirVec
    if trafficBlock.timer > trafficBlock.timerLimit and not graph[wp1][wp2].inNode and (radius[wp1] + radius[wp2]) * 0.5 > ai.length then
      dirVec = -aiDirVec -- tries to plan reverse direction
    else
      dirVec = aiDirVec
    end

    wp1, wp2 = pickAiWp(wp1, wp2, dirVec)

    -- local newRoute = mapData:getRandomPathG(wp1, aiDirVec, getMinPlanLen(), 0.4, 1 / (aiSpeed + 1e-30))
    --newRoute = mapData:getRandomPathG(wp1, dirVec, getMinPlanLen(), 0.4, math.huge)
    local path = mapData:getPathT(wp1, aiPos, getMinPlanLen(), 1e4, aiDirVec)

    if path[2] == wp2 and path[3] then
      if (position[wp2] - position[wp1]):dot(aiDirVec) < 0 then
        table.remove(path, 1)
      end
    end
    ai.currentSegment[1] = wp1
    ai.currentSegment[2] = wp2

    if path and path[1] then
      local route = planAhead(path, currentRoute)

      if route and route.plan then
        trafficBlock.timerLimit = max(1, parameters.trafficWaitTime * 2)
        intersection = {timer = 0, turn = 0, block = false}

        if trafficBlock.timer > trafficBlock.timerLimit and trafficAction.hornTimer == -1 then
          trafficBlock.timer = 0
          if not trafficBlock.hornFlag then
            trafficAction.hornTimer = 0 -- activates horn
            trafficBlock.hornFlag = true -- prevents horn from triggering again while stopped
          end

          currentRoute = route
          return
        elseif not currentRoute then
          currentRoute = route
          return
        elseif route.plan.targetSpeed >= min(currentRoute.plan.targetSpeed, aiSpeed) and targetsCompatible(currentRoute, route) then
          currentRoute = route
          return
        elseif currentRoute.plan.reRoute then
          --currentRoute = route
          trafficActions()
          planAhead(currentRoute)
          return
          -- local targetSpeed = max(0, aiSpeed - sqrt(max(0, square(staticFrictionCoef * g) - square(sensors.gx2))) * dt)
          -- currentRoute.plan.targetSpeed = min(currentRoute.plan.targetSpeed, targetSpeed)
        end
      end
    end
  end

  trafficActions()
  planAhead(currentRoute)
end

local function warningAIDisabled(message)
  guihooks.message(message, 5, "AI debug")
  M.mode = 'disabled'
  M.updateGFX = nop
  resetMapAndRoute()
  stateChanged()
end

local function offRoadFollowControl()
  if not player or not player.pos or not aiPos or not aiSpeed then return 0, 0, 0 end

  local ai2PlVec = player.pos - aiPos
  local ai2PlDist = ai2PlVec:length()
  local ai2PlDirVec = ai2PlVec / (ai2PlDist + 1e-30)
  local plSpeedFromAI = player.vel:dot(ai2PlDirVec)
  ai2PlDist = max(0, ai2PlDist - 12)
  local targetSpeed = sqrt(max(0, abs(plSpeedFromAI) * plSpeedFromAI + 2 * g * min(aggression, staticFrictionCoef) * ai2PlDist))
  local speedDif = targetSpeed - aiSpeed
  local throttle = clamp(speedDif, 0, 1)
  local brake = clamp(-speedDif, 0, 1)

  return throttle, brake, targetSpeed
end

local function drivabilityChangeReroute()
  -- Description: handle changes in edge drivabilities
  -- This function compares the current ai path for collisions with the drivability change set
  -- if there is an edge along the current path that had its drivability decreased
  -- a flag is raised (currentRoute.plan.reRoute) then handled by the appropriate planner

  if currentRoute ~= nil then
    -- changeSet format: {nodeA1, nodeB1, driv1, nodeA2, nodeB2, driv2, ...}
    local changeSet = mapmgr.changeSet
    local changeSetCount = #changeSet
    local changeSetDict = table.new(0, 2 * (changeSetCount / 3))

    -- populate the changeSetDict with the changeSet nodes
    for i = 1, changeSetCount, 3 do
      if changeSet[i+2] < 0 then
        changeSetDict[changeSet[i]] = true
        changeSetDict[changeSet[i+1]] = true
      end
    end

    local path = currentRoute.path
    local nodeCollisionIdx
    for i = currentRoute.plan[2].pathidx, #path do
      if changeSetDict[path[i]] then
        -- if there is a collision continue with a thorough check (edges against edges)
        nodeCollisionIdx = i
        break
      end
    end

    if nodeCollisionIdx then
      table.clear(changeSetDict)
      local edgeTab = {'','\0',''}
      -- populate the changeSetDict with changeSet edges
      for i = 1, changeSetCount, 3 do
        if changeSet[i+2] < 0 then
          local nodeA, nodeB = changeSet[i], changeSet[i+1]
          edgeTab[1] = nodeA < nodeB and nodeA or nodeB
          edgeTab[3] = nodeA == edgeTab[1] and nodeB or nodeA
          changeSetDict[tableConcat(edgeTab)] = true
        end
      end

      local edgeCollisionIdx
      -- compare path edges with changeSetDict edges starting with the earliest edge containing the initialy detected node collision
      for i = max(currentRoute.plan[2].pathidx, nodeCollisionIdx - 1), #path-1 do
        local nodeA, nodeB = path[i], path[i+1]
        edgeTab[1] = nodeA < nodeB and nodeA or nodeB
        edgeTab[3] = nodeA == edgeTab[1] and nodeB or nodeA
        if changeSetDict[tableConcat(edgeTab)] then
          edgeCollisionIdx = i
          currentRoute.plan.reRoute = edgeCollisionIdx
          break
        end
      end

      -- if edgeCollisionIdx then
      --   -- find closest possible diversion point from edgeCollisionIdx
      --   local graph = mapData.graph
      --   for i = edgeCollisionIdx, currentRoute.plan[2].pathidx, -1 do
      --     local node = path[i]
      --     if tableSize(graph[node]) > 2 then

      --     end
      --   end
      --   dump(objectId, edgeCollisionIdx, path[edgeCollisionIdx], path[edgeCollisionIdx+1])
      -- end
    end
  end
end

M.updateGFX = nop
local function updateGFX(dtGFX)
  dt = dtGFX

  if mapData ~= mapmgr.mapData then
    currentRoute = nil
  end

  if mapmgr.changeSet then
    drivabilityChangeReroute()
    mapmgr.changeSet = nil
  end

  mapData = mapmgr.mapData
  signalsData = mapmgr.signalsData

  if mapData == nil then return end

  -- local cgPos = obj:calcCenterOfGravity()
  -- aiPos:set(cgPos)
  -- aiPos.z = obj:getSurfaceHeightBelow(cgPos)
  aiPos:set(obj:getFrontPosition())
  aiPos.z = max(aiPos.z - 1, obj:getSurfaceHeightBelow(aiPos))
  ai.prevDirVec:set(aiDirVec)
  aiDirVec:set(obj:getDirectionVectorXYZ())
  ai.upVec:set(obj:getDirectionVectorUp())
  ai.rightVec:set(cross(aiDirVec, ai.upVec)); ai.rightVec:normalize()
  ai.vel:set(obj:getSmoothRefVelocityXYZ())
  aiSpeed = ai.vel:length()
  ai.width = ai.width or obj:getInitialWidth()
  ai.length = ai.length or obj:getInitialLength()
  staticFrictionCoef = parameters.staticFrictionCoefMult * obj:getStaticFrictionCoef() -- depends on ground model, tire and tire load

  misc.logData()

  if max(lastCommand.throttle, lastCommand.throttle) > 0.5 and aiSpeed < 1 then
    aiCannotMoveTime = aiCannotMoveTime + dt
  else
    aiCannotMoveTime = 0
  end

  if aiSpeed < 3 then
    trafficSide.cTimer = trafficSide.cTimer + dt
    trafficSide.timer = (trafficSide.timer + dt) % (2 * trafficSide.timerLimit)
    trafficSide.side = sign2(trafficSide.timerLimit - trafficSide.timer)
  else
    trafficSide.cTimer = max(0, trafficSide.cTimer - dt)
    trafficSide.timer = 0
    trafficSide.side = 1
  end

  changePlanTimer = max(0, changePlanTimer - dt)

  -- local wp1, wp2 = mapmgr.findClosestRoad(aiPos)
  -- if (mapData.positions[wp2] - mapData.positions[wp1]):dot(aiDirVec) > 0 then
  --   wp1, wp2 = wp2, wp1
  -- end
  -- ai.currentSegment = {wp1, wp2}
  ai.currentSegment[1] = nil
  ai.currentSegment[2] = nil

  ------------------ RANDOM MODE ----------------
  if M.mode == 'random' then
    local route
    if not currentRoute or currentRoute.plan.reRoute or currentRoute.plan.planLen + getPathLen(currentRoute.path, currentRoute.plan[currentRoute.plan.planCount].pathidx) < getMinPlanLen() then
      local wp1, wp2 = mapmgr.findClosestRoad(aiPos)
      if wp1 == nil or wp2 == nil then
        warningAIDisabled("Could not find a road network, or closest road is too far")
        return
      end
      ai.currentSegment[1] = wp1
      ai.currentSegment[2] = wp2

      if internalState == 'offroad' then
        local vec1 = mapData.positions[wp1] - aiPos
        local vec2 = mapData.positions[wp2] - aiPos
        if aiDirVec:dot(vec1) > 0 and aiDirVec:dot(vec2) > 0 then
          if vec1:squaredLength() > vec2:squaredLength() then
            wp1, wp2 = wp2, wp1
          end
        elseif aiDirVec:dot(mapData.positions[wp2] - mapData.positions[wp1]) > 0 then
          wp1, wp2 = wp2, wp1
        end
      elseif aiDirVec:dot(mapData.positions[wp2] - mapData.positions[wp1]) > 0 then
        wp1, wp2 = wp2, wp1
      end

      local path = mapData:getRandomPath(wp1, wp2, driveInLaneFlag and 1e4 or 1)

      if path and path[1] then
        local route = planAhead(path, currentRoute)
        if route and route.plan then
          if not currentRoute then
            currentRoute = route
          else
            local curPlanIdx = currentRoute.plan[2].pathidx
            local curPathCount = #currentRoute.path
            if curPlanIdx >= curPathCount * 0.9 or (targetsCompatible(currentRoute, route) and route.plan.targetSpeed >= aiSpeed) then
              currentRoute = route
            end
          end
        end
      end
    end

    if currentRoute ~= route then
      planAhead(currentRoute)
    end

  ------------------ TRAFFIC MODE ----------------
  elseif M.mode == 'traffic' then
    trafficPlan()

  ------------------ MANUAL MODE ----------------
  elseif M.mode == 'manual' then
    if validateInput(wpList or manualPath) then newManualPath() end

    if aggressionMode == 'rubberBand' then
      updatePlayerData()
      if player ~= nil then
        if (aiPos - player.pos):dot(aiDirVec) > 0 then
          setAggressionInternal(max(min(0.1 + max((150 - player.pos:distance(aiPos))/150, 0), M.extAggression), 0.5))
        else
          setAggressionInternal()
        end
      end
    end

    planAhead(currentRoute)

  ------------------ SPAN MODE ------------------
  elseif M.mode == 'span' then
    if currentRoute == nil then
      local positions = mapData.positions
      local wpAft, wpFore = mapmgr.findClosestRoad(aiPos)
      if not (wpAft and wpFore) then
        warningAIDisabled("Could not find a road network, or closest road is too far")
        return
      end
      if aiDirVec:dot(positions[wpFore] - positions[wpAft]) < 0 then wpAft, wpFore = wpFore, wpAft end

      ai.currentSegment[1] = wpFore
      ai.currentSegment[2] = wpAft

      local target, targetLink

      if not (edgeDict and edgeDict[1]) then
        -- creates the edgeDict and returns a random edge
        target, targetLink = getMapEdges(M.cutOffDrivability or 0, wpFore)
        if not target then
          warningAIDisabled("No available target with selected characteristics")
          return
        end
      end

      local path = {}
      while true do
        if not target then
          local maxDist = -math.huge
          local lim = 1
          repeat
            -- get most distant non walked edge
            for k, v in pairs(edgeDict) do
              if v <= lim then
                if lim > 1 then edgeDict[k] = 1 end
                local i = string.find(k, '\0')
                local n1id = string.sub(k, 1, i-1)
                local sqDist = positions[n1id]:squaredDistance(aiPos)
                if sqDist > maxDist then
                  maxDist = sqDist
                  target = n1id
                  targetLink = string.sub(k, i+1, #k)
                end
              end
            end
            lim = math.huge -- if the first iteration does not produce a target
          until target
        end

        local nodeDegree = 1
        for lid, _ in pairs(mapData.graph[target]) do
          -- we're looking for neighboring nodes other than the targetLink
          if lid ~= targetLink then
            nodeDegree = nodeDegree + 1
          end
        end
        if nodeDegree == 1 then
          local key = target..'\0'..targetLink
          edgeDict[key] = edgeDict[key] + 1
        end

        path = mapData:spanMap(wpFore, wpAft, target, edgeDict, driveInLaneFlag and 1e7 or 1)

        if not path[2] and wpFore ~= target then
          -- remove edge from edgeDict list and get a new target (while loop will iterate again)
          edgeDict[target..'\0'..targetLink] = nil
          edgeDict[targetLink..'\0'..target] = nil
          target = nil
          if next(edgeDict) == nil then
            warningAIDisabled("Could not find a path to any of the possible targets")
            return
          end
        elseif not path[1] then
          warningAIDisabled("No Route Found")
          return
        else
          -- insert the second edge node in newRoute if it is not already contained
          local pathCount = #path
          if path[pathCount-1] ~= targetLink then path[pathCount+1] = targetLink end
          break
        end
      end

      local route = planAhead(path)
      if not route then return end
      currentRoute = route
    else
      planAhead(currentRoute)
    end

  ------------------ FLEE MODE ------------------
  elseif M.mode == 'flee' then
    updatePlayerData()
    if player then
      if validateInput() then
        targetWPName = wpList[1]
        wpList = nil
      end

      fleePlan()

      if internalState == 'offroad' then
        local targetPos = aiPos + (aiPos - player.pos) * 100
        local targetSpeed = math.huge
        driveToTarget(targetPos, 1, 0, targetSpeed)
        return
      end
    else
      -- guihooks.message("No vehicle to Flee from", 5, "AI debug") -- TODO: this freezes the up because it runs on the gfx step
      return
    end

  ------------------ CHASE MODE ------------------
  elseif M.mode == 'chase' or M.mode == 'follow' then
    updatePlayerData()
    if player then
      chasePlan()

      if internalState == 'tail' then
        --internalState = 'onroad'
        --currentRoute = nil
        local plai = player.pos - aiPos
        local relvel = ai.vel:dot(plai) - player.vel:dot(plai)
        if chaseData.playerState == 'stopped' then
          driveToTarget(player.pos, 0, 1, 0)
        elseif relvel > 0 then
          driveToTarget(player.pos + (plai:length() / (relvel + 1e-30)) * player.vel, 1, 0, math.huge)
        else
          driveToTarget(player.pos, 1, 0, math.huge)
        end
        return
      elseif internalState == 'offroad' then
        if M.mode == 'follow' then
          local throttle, brake, targetSpeed = offRoadFollowControl()
          driveToTarget(player.pos, throttle, brake, targetSpeed)
        else
          driveToTarget(player.pos, 1, 0, math.huge)
        end
        return
      elseif currentRoute == nil then
        driveCar(0, 0, 0, 1)
        return
      end

    else
      -- guihooks.message("No vehicle to Chase", 5, "AI debug")
      return
    end

  ------------------ STOP MODE ------------------
  elseif M.mode == 'stop' then
    if currentRoute then
      planAhead(currentRoute)
      local targetSpeed = max(0, aiSpeed - sqrt(max(0, square(staticFrictionCoef * g) - square(sensors.gx2))) * dt)
      currentRoute.plan.targetSpeed = min(currentRoute.plan.targetSpeed, targetSpeed)
    elseif ai.vel:dot(aiDirVec) > 0 then
      driveCar(0, 0, 0.5, 0)
    else
      driveCar(0, 1, 0, 0)
    end
    if aiSpeed < 0.08 then
      driveCar(0, 0, 0, 1)
      M.mode = 'disabled'
      M.manualTargetName = nil
      M.updateGFX = nop
      resetMapAndRoute()
      stateChanged()
      if controller.mainController and restoreGearboxMode then
        controller.mainController.setGearboxMode('realistic')
      end
      return
    end
  end
  -----------------------------------------------

  if currentRoute then
    local plan = currentRoute.plan
    local targetPos = plan.targetPos
    local aiSeg = plan.aiSeg

    -- cleanup path if it has gotten too long
    if not race and plan[aiSeg].pathidx >= 10 and currentRoute.path[20] then
      local path = currentRoute.path
      local k = plan[aiSeg].pathidx - 2
      for i = 1, #path do
        path[i] = path[k+i]
      end
      for i = 1, plan.planCount do
        plan[i].pathidx = plan[i].pathidx - k
      end
    end

    local targetSpeed = plan.targetSpeed

    if ai.upVec:dot(gravityDir) >= -0.2588 then -- vehicle upside down
      driveCar(0, 0, 0, 0)
      return
    end

    local lowTargetSpeedVal = 0.24
    if not plan[aiSeg+2] and ((targetSpeed < lowTargetSpeedVal and aiSpeed < 0.15) or (targetPos - aiPos):dot(aiDirVec) < 0) then
      if M.mode == 'span' then
        local path = currentRoute.path
        for i = 1, #path - 1 do
          local key = path[i]..'\0'..path[i+1]
          -- in case we have gone over an edge that is not in the edgeDict list
          edgeDict[key] = edgeDict[key] and (edgeDict[key] * 20)
        end
      end

      driveCar(0, 0, 0, 1)
      aistatus('route done', 'route')
      guihooks.message("Route done", 5, "AI debug")
      currentRoute = nil
      return
    end

    -- come off controls when close to intermediate node with zero speed (ex. intersection), arcade autobrake takes over
    if (plan[aiSeg+1].speed == 0 and plan[aiSeg+2]) and aiSpeed < 0.15 then
      driveCar(0, 0, 0, 0)
      return
    end

    if electrics.values.ignitionLevel == 3 then
      if aiSpeed < 1.5 then
        driveCar(0, 0, 0, 1)
      end
      return
    end

    if not controller.isFrozen and aiSpeed < 0.1 and targetSpeed > 0.5 and (lastCommand.throttle ~= 0 or lastCommand.brake ~= 0) then
      crash.time = crash.time + dt
      if crash.time > 1 then
        crash.dir = vec3(aiDirVec)
        crash.manoeuvre = 1
      end
    else
      crash.time = 0
    end

    -- Throttle and Brake control
    local speedDif = targetSpeed - aiSpeed
    local rate = targetSpeedDifSmoother[speedDif > 0 and targetSpeedDifSmoother.state >= 0 and speedDif >= targetSpeedDifSmoother.state]
    speedDif = targetSpeedDifSmoother:getWithRate(speedDif, dt, rate)

    local legalSpeedDif = plan.targetSpeedLegal - aiSpeed
    local lowSpeedDif = min(speedDif - clamp((aiSpeed - 2) * 0.5, 0, 1), legalSpeedDif) * 0.5
    local lowTargSpeedConstBrake = lowTargetSpeedVal - targetSpeed -- apply constant brake below some targetSpeed

    local throttle = clamp(lowSpeedDif, 0, 1) * sign(max(0, -lowTargSpeedConstBrake)) -- throttle not enganged for targetSpeed < 0.26

    local brakeLimLow = sign(max(0, lowTargSpeedConstBrake)) * 0.5
    local brake = clamp(-speedDif, brakeLimLow, 1) * sign(max(0, electrics.values.smoothShiftLogicAV or 0 - 3)) -- arcade autobrake comes in at |smoothShiftLogicAV| < 5

    driveToTarget(targetPos, throttle, brake)
  end
end

local function debugDraw(focusPos)
  local debugDrawer = obj.debugDrawProxy

  if M.mode == 'script' and scriptai ~= nil then
    scriptai.debugDraw()
  end

  if currentRoute then
    local plan = currentRoute.plan
    local targetPos = plan.targetPos
    local targetSpeed = plan.targetSpeed
    if targetPos then
      debugDrawer:drawSphere(0.25, targetPos, color(255,0,0,255))

      local aiSeg = plan.aiSeg
      local shadowPos = currentRoute.plan[aiSeg].pos + plan.aiXnormOnSeg * (plan[aiSeg+1].pos - plan[aiSeg].pos)
      local blue = color(0,0,255,255)
      debugDrawer:drawSphere(0.25, shadowPos, blue)

      for plID, _ in pairs(mapmgr.getObjects()) do
        if plID ~= objectId then
          debugDrawer:drawSphere(0.25, obj:getObjectFrontPosition(plID), blue)
        end
      end

      if player then
        debugDrawer:drawSphere(0.3, player.pos, color(0,255,0,255))
      end
    end

    if M.debugMode == 'target' then
      if mapData and mapData.graph and currentRoute.path then
        local p = mapData.positions[currentRoute.path[#currentRoute.path]]
        --debugDrawer:drawSphere(4, p, color(255,0,0,100))
        --debugDrawer:drawText(p + vec3(0, 0, 4), color(0,0,0,255), 'Destination')
      end

    elseif M.debugMode == 'route' then
      if currentRoute.path then
        local p = mapData.positions[currentRoute.path[#currentRoute.path]]
        debugDrawer:drawSphere(4, p, color(255,0,0,100))
        debugDrawer:drawText(p + vec3(0, 0, 4), color(0,0,0,255), 'Destination')
      end

      local maxCount = 700
      local last = routeRec.last
      local count = min(#routeRec, maxCount)
      if count == 0 or routeRec[last]:squaredDistance(aiPos) > (7 * 7) then
        last = 1 + last % maxCount
        routeRec[last] = vec3(aiPos)
        count = min(count+1, maxCount)
        routeRec.last = last
      end

      local tmpVec = vec3(0.7, ai.width, 0.7)
      local black = color(0,0,0,128)
      for i = 1, count-1 do
        debugDrawer:drawSquarePrism(routeRec[1+(last+i-1)%count], routeRec[1+(last+i)%count], tmpVec, tmpVec, black)
      end

      if currentRoute.plan[1].pathidx then
        local positions = mapData.positions
        local path = currentRoute.path
        tmpVec:setAdd(vec3(0, ai.width, 0))
        local transparentRed = color(255,0,0,120)
        for i = currentRoute.plan[1].pathidx, #path - 1 do
          debugDrawer:drawSquarePrism(positions[path[i]], positions[path[i+1]], tmpVec, tmpVec, transparentRed)
        end
      end

    elseif M.debugMode == 'speeds' then
      -- Debug Throttle brake application
      local maxCount = 175
      local count = min(#trajecRec, maxCount)
      local last = trajecRec.last
      if count == 0 or trajecRec[last][1]:squaredDistance(aiPos) > (0.2 * 0.2) then
        last = 1 + last % maxCount
        trajecRec[last] = {vec3(aiPos), aiSpeed, targetSpeed, lastCommand.brake, lastCommand.throttle}
        count = min(count+1, maxCount)
        trajecRec.last = last
      end

      local tmpVec1 = vec3(0.7, ai.width, 0.7)
      for i = 1, count-1 do
        local n = trajecRec[1 + (last + i) % count]
        debugDrawer:drawSquarePrism(trajecRec[1 + (last + i - 1) % count][1], n[1], tmpVec1, tmpVec1, color(255 * sqrt(abs(n[4])), 255 * sqrt(n[5]), 0, 100))
      end

      local prevEntry
      local zOffSet = vec3(0, 0, 0.4)
      local yellow, blue = color(255,255,0,200), color(0,0,255,200)
      local tmpVec2 = vec3()
      for i = 1, count-1 do
        local v = trajecRec[1 + (last + i - 1) % count]
        if prevEntry then
          -- actuall speed
          tmpVec1:set(0, 0, prevEntry[2] * 0.2)
          tmpVec2:set(0, 0, v[2] * 0.2)
          debugDrawer:drawCylinder(prevEntry[1] + tmpVec1, v[1] + tmpVec2, 0.02, yellow)

          -- target speed
          tmpVec1:set(0, 0, prevEntry[3] * 0.2)
          tmpVec2:set(0, 0, v[3] * 0.2)
          debugDrawer:drawCylinder(prevEntry[1] + tmpVec1, v[1] + tmpVec2, 0.02, blue)
        end

        tmpVec1:set(0, 0, v[3] * 0.2)
        debugDrawer:drawCylinder(v[1], v[1] + tmpVec1, 0.01, blue)

        if focusPos:squaredDistance(v[1]) < labelRenderDistance * labelRenderDistance then
          tmpVec1:set(0, 0, v[2] * 0.2)
          debugDrawer:drawText(v[1] + tmpVec1 + zOffSet, yellow, strFormat("%2.0f", v[2]*3.6).." kph")

          tmpVec1:set(0, 0, v[3] * 0.2)
          debugDrawer:drawText(v[1] + tmpVec1 + zOffSet, blue, strFormat("%2.0f", v[3]*3.6).." kph")
        end
        prevEntry = v
      end

      -- Planned speeds
      if plan[1] then
        local red = color(255,0,0,200) -- getContrastColor(objectId)
        local black = color(0, 0, 0, 255)
        local green = color(0, 255, 0, 200)
        local prevSpeed = -1
        local prevLegalSpeed = -1
        local drawLen = 0
        local prevPoint = plan[1].pos
        local prevPoint_ = plan[1].pos
        local tmpVec = vec3()
        for i = 1, #plan do
          local n = plan[i]

          local speed = (n.speed >= 0 and n.speed) or prevSpeed
          tmpVec:set(0, 0, speed * 0.2)
          local p1 = n.pos + tmpVec
          debugDrawer:drawCylinder(n.pos, p1, 0.03, red)
          debugDrawer:drawCylinder(prevPoint, p1, 0.05, red)
          debugDrawer:drawText(p1, black, strFormat("%2.0f", speed*3.6).." kph")
          prevSpeed = speed
          prevPoint = p1

          if M.speedMode == 'legal' then
            local legalSpeed = (n.legalSpeed >= 0 and n.legalSpeed) or prevLegalSpeed
            tmpVec:set(0, 0, legalSpeed * 0.2)
            local p1_ = n.pos + tmpVec
            debugDrawer:drawCylinder(n.pos, p1_, 0.03, green)
            debugDrawer:drawCylinder(prevPoint_, p1_, 0.05, green)
            debugDrawer:drawText(p1_, black, strFormat("%2.0f", legalSpeed*3.6).." kph")
            prevLegalSpeed = legalSpeed
            prevPoint_ = p1_
          end

          --[[
          drawLen = drawLen + n.vec:length()
          if traffic and traffic[i] then
            for _, data in ipairs(traffic[i]) do
              local plPosOnPlan = linePointFromXnorm(n.pos, plan[i+1].pos, data[2])
              debugDrawer:drawSphere(0.25, plPosOnPlan, color(0,255,0,100))
            end
          end
          if drawLen > 150 then break end
          --]]
        end

        --[[ Debug road width and lane limits
        local prevPointOrig = plan[1].posOrig
        local tmpVec = vec3(0.5, 0.5, 0.5)
        for i = 1, #plan do
          local n = plan[i]
          local p1Orig = n.posOrig - n.biNormal
          debugDrawer:drawCylinder(n.posOrig, p1Orig, 0.03, black)
          debugDrawer:drawCylinder(p1Orig, p1Orig + n.normal, 0.03, black)
          debugDrawer:drawCylinder(prevPointOrig, p1Orig, 0.03, black)
          local roadHalfWidth = n.radiusOrig * n.chordLength
          debugDrawer:drawCylinder(n.posOrig, p1Orig, roadHalfWidth, color(255, 0, 0, 40))
          if n.limLeft and n.limRight then -- You need to uncomment the appropriate code in planAhead force integrator loop for this to work
            debugDrawer:drawSquarePrism(n.posOrig + (n.limLeft - roadHalfWidth) * n.normal, n.posOrig + (n.limRight - roadHalfWidth) * n.normal, tmpVec, tmpVec, color(0,0,255,120))
          end
          prevPointOrig = p1Orig
        end
        --]]

        --[[ Debug lane change. You need to uncomment upvalue newPositionsDebug for this to work
        if newPositionsDebug[1] then
          local green = color(0,255,0,200)
          local prevPoint = newPositionsDebug[1]
          for i = 1, #newPositionsDebug do
            local pos = newPositionsDebug[i]
            local p1 = pos + vec3(0, 0, 2)
            debugDrawer:drawCylinder(pos, p1, 0.03, green)
            debugDrawer:drawCylinder(prevPoint, p1, 0.05, green)
            prevPoint = p1
          end
        end
        --]]
      end

      -- Player segment visual debug for chase / follow mode
      -- if chaseData.playerRoad then
      --   local col1, col2
      --   if internalState == 'tail' then
      --     col1 = color(0,0,0,200)
      --     col2 = color(0,0,0,200)
      --   else
      --     col1 = color(255,0,0,100)
      --     col2 = color(0,0,255,100)
      --   end
      --   local plwp1 = chaseData.playerRoad[1]
      --   debugDrawer:drawSphere(2, mapData.positions[plwp1], col1)
      --   local plwp2 = chaseData.playerRoad[2]
      --   debugDrawer:drawSphere(2, mapData.positions[plwp2], col2)
      -- end

    elseif M.debugMode == 'trajectory' then
      -- Debug Curvatures
      -- local plan = currentRoute.plan
      -- if plan ~= nil then
      --   local prevPoint = plan[1].pos
      --   for i = 1, #plan do
      --     local p = plan[i].pos
      --     local v = plan[i].curvature or 1e-10
      --     local scaledV = abs(1000 * v)
      --     debugDrawer:drawCylinder(p, p + vec3(0, 0, scaledV), 0.06, color(abs(min(fsign(v),0))*255,max(fsign(v),0)*255,0,200))
      --     debugDrawer:drawText(p + vec3(0, 0, scaledV), color(0,0,0,255), strFormat("%5.4e", v))
      --     debugDrawer:drawCylinder(prevPoint, p + vec3(0, 0, scaledV), 0.06, col)
      --     prevPoint = p + vec3(0, 0, scaledV)
      --   end
      -- end

      -- Debug Planned Speeds
      if plan[1] then
        local col = getContrastColor(objectId)
        local prevPoint = plan[1].pos
        local prevSpeed = -1
        local drawLen = 0
        for i = 1, #plan do
          local n = plan[i]
          local p = n.pos
          local v = (n.speed >= 0 and n.speed) or prevSpeed
          local p1 = p + vec3(0, 0, v*0.2)
          --debugDrawer:drawLine(p + vec3(0, 0, v*0.2), (n.pos + n.turnDir) + vec3(0, 0, v*0.2), col)
          debugDrawer:drawCylinder(p, p1, 0.03, col)
          debugDrawer:drawCylinder(prevPoint, p1, 0.05, col)
          debugDrawer:drawText(p1, color(0,0,0,255), strFormat("%2.0f", v*3.6) .. " kph")
          prevPoint = p1
          prevSpeed = v
          drawLen = drawLen + n.vec:length()
          if drawLen > 80 then break end
        end
      end

      -- Debug Throttle brake application
      local maxCount = 175
      local count = min(#trajecRec, maxCount)
      local last = trajecRec.last
      if count == 0 or trajecRec[last][1]:squaredDistance(aiPos) > (0.25 * 0.25) then
        last = 1 + last % maxCount
        trajecRec[last] = {vec3(aiPos), lastCommand.throttle, lastCommand.brake}
        count = min(count+1, maxCount)
        trajecRec.last = last
      end

      local tmpVec = vec3(0.7, ai.width, 0.7)
      for i = 1, count-1 do
        local n = trajecRec[1+(last+i)%count]
        debugDrawer:drawSquarePrism(trajecRec[1+(last+i-1)%count][1], n[1], tmpVec, tmpVec, color(255 * sqrt(abs(n[3])), 255 * sqrt(n[2]), 0, 100))
      end
    end
  end
end

local function setAvoidCars(v)
  M.extAvoidCars = v
  if M.extAvoidCars == 'off' or M.extAvoidCars == 'on' then
    avoidCars = M.extAvoidCars
  else
    avoidCars = M.mode == 'manual' and 'off' or 'on'
  end
  stateChanged()
end

local function driveInLane(v)
  if v == 'on' then
    M.driveInLaneFlag = 'on'
    driveInLaneFlag = true
  else
    M.driveInLaneFlag = 'off'
    driveInLaneFlag = false
  end
  stateChanged()
end

local function setMode(mode)
  if mode ~= nil then
    if M.mode ~= mode then -- new AI mode is not the same as the old one
      obj:queueGameEngineLua('onAiModeChange('..objectId..', "'..mode..'")')
    end
    M.mode = mode
  end

  if M.extAvoidCars == 'off' or M.extAvoidCars == 'on' then
    avoidCars = M.extAvoidCars
  else
    avoidCars = (M.mode == 'manual' and 'off' or 'on')
  end

  if M.mode ~= 'script' then
    if M.mode ~= 'disabled' and M.mode ~= 'stop' then
      resetMapAndRoute()

      mapmgr.requestMap() -- a map request is also performed in the startFollowing function of scriptai
      M.updateGFX = updateGFX
      targetSpeedDifSmoother = newTemporalSmoothingNonLinear(1e300, 4, vec3(obj:getSmoothRefVelocityXYZ()):length())

      if controller.mainController then
        if electrics.values.gearboxMode == 'realistic' then
          restoreGearboxMode = true
        end
        controller.mainController.setGearboxMode('arcade')
      end

      ai.wheelBase = calculateWheelBase()
    end

    if M.mode == 'disabled' then
      driveCar(0, 0, 0, 0)
      M.updateGFX = nop
      currentRoute = nil
      if controller.mainController and restoreGearboxMode then
        controller.mainController.setGearboxMode('realistic')
      end
    end

    if M.mode == 'flee' or M.mode == 'chase' or M.mode == 'follow' then
      setAggressionMode('rubberBand')
    end

    if M.mode == 'traffic' then
      setSpeedMode('legal')
      obj:setSelfCollisionMode(2)
      obj:setAerodynamicsMode(2)
    else
      obj:setSelfCollisionMode(1)
      obj:setAerodynamicsMode(1)
    end

    stateChanged()
    sounds.updateObjType()
  end

  trajecRec = {last = 0}
  routeRec = {last = 0}
end

local function toggleTrafficMode()
  if M.mode == "traffic" then
    setMode("stop")
  else
    driveInLane('on')
    setMode("traffic")
  end
end

local function reset() -- called when the user pressed I
  M.manualTargetName = nil
  resetTrafficTables()

  throttleSmoother:set(0)
  smoothTcs:set(1)

  if M.mode ~= 'disabled' then
    driveCar(0, 0, 0, 0)
    setMode() -- some scenarios don't work if this is changed to setMode('disabled')
  end
  stateChanged()
end

local function resetLearning()
end

local function setVehicleDebugMode(newMode)
  tableMerge(M, newMode)
  if M.debugMode ~= 'trajectory' then
    trajecRec = {last = 0}
  end
  if M.debugMode ~= 'route' then
    routeRec = {last = 0}
  end
  if M.debugMode ~= 'speeds' then
    trajecRec = {last = 0}
  end
  if M.debugMode ~= 'off' then
    M.debugDraw = debugDraw
  else
    M.debugDraw = nop
  end
end

local function setState(newState)
  if newState.mode and newState.mode ~= M.mode then -- new AI mode is not the same as the old one
    obj:queueGameEngineLua('onAiModeChange('..objectId..', "'..newState.mode..'")')
  end

  local mode = M.mode
  tableMerge(M, newState)
  setAggressionExternal(M.extAggression)

  -- after a reload (cntr-R) vehicle should be left with handbrake engaged if ai is disabled
  -- preserve initial state of vehicle controls (handbrake engaged) if current mode and new mode are both 'disabled'
  if not (mode == 'disabled' and M.mode == 'disabled') then
    setMode()
  end

  setVehicleDebugMode(M)
  setTargetObjectID(M.targetObjectID)
  stateChanged()
end

local function setTarget(wp)
  M.manualTargetName = wp
  validateInput = validateUserInput
  wpList = {wp}
end

local function setPath(path)
  manualPath = path
  validateInput = validateUserInput
end

local function driveUsingPath(arg)
  --[[ At least one argument of either path or wpTargetList must be specified. All other arguments are optional.

  * path: A sequence of waypoint names that form a path by themselves to be followed in the order provided.
  * wpTargetList: Type: A sequence of waypoint names to be used as succesive targets ex. wpTargetList = {'wp1', 'wp2'}.
                  Between any two consequitive waypoints a shortest path route will be followed.

  -- Optional Arguments --
  * wpSpeeds: Type: (key/value pairs, key: "node_name", value: speed, number in m/s)
              Define target speeds for individual waypoints. The ai will try to meet this speed when at the given waypoint.
  * noOfLaps: Type: number. Default value: nil
              The number of laps if the path is a loop. If not defined, the ai will just follow the succesion of waypoints once.
  * routeSpeed: A speed in m/s. To be used in tandem with "routeSpeedMode".
                Type: number
  * routeSpeedMode: Values: 'limit': the ai will not go above the 'routeSpeed' defined by routeSpeed.
                            'set': the ai will try to always go at the speed defined by "routeSpeed".
  * driveInLane: Values: 'on' (anything else is considered off/inactive)
                 When 'on' the ai will keep on the correct side of the road on two way roads.
                 This also affects pathFinding in that when this option is active ai paths will traverse roads in the legal direction if posibble.
                 Default: inactive
  * aggression: Value: 0.3 - 1. The aggression value with which the ai will drive the route.
                At 1 the ai will drive at the limit of traction. A value of 0.3 would be considered normal every day driving, going shopping etc.
                Default: 0.3
  * avoidCars: Values: 'on' / 'off'.  When 'on' the ai will be aware of (avoid crashing into) other vehicles on the map. Default is 'off'
  * examples:
  ai.driveUsingPath{ wpTargetList = {'wp1', 'wp10'}, driveInLane = 'on', avoidCars = 'on', routeSpeed = 35, routeSpeedMode = 'limit', wpSpeeds = {wp1 = 10, wp2 = 40}, aggression = 0.3}
  In the above example the speeds set for wp1 and wp2 will take precedence over "routeSpeed" for the specified nodes.
  --]]

  if (arg.wpTargetList == nil and arg.path == nil and arg.script == nil) or
    (type(arg.wpTargetList) ~= 'table' and type(arg.path) ~= 'table' and type(arg.script) ~= 'table') or
    (arg.wpSpeeds ~= nil and type(arg.wpSpeeds) ~= 'table') or
    (arg.noOfLaps ~= nil and type(arg.noOfLaps) ~= 'number') or
    (arg.routeSpeed ~= nil and type(arg.routeSpeed) ~= 'number') or
    (arg.routeSpeedMode ~= nil and type(arg.routeSpeedMode) ~= 'string') or
    (arg.driveInLane ~= nil and type(arg.driveInLane) ~= 'string') or
    (arg.aggression ~= nil and type(arg.aggression) ~= 'number')
  then
    return
  end

  if arg.resetLearning then
    resetLearning()
  end

  setState({mode = 'manual'})
  setParameters({driveStyle = arg.driveStyle or 'default',
                staticFrictionCoefMult = max(0.95, arg.staticFrictionCoefMult or 0.95),
                lookAheadKv = max(0.1, arg.lookAheadKv or 0.65)})

  noOfLaps = arg.noOfLaps and max(arg.noOfLaps, 1) or 1
  wpList = arg.wpTargetList
  manualPath = arg.path
  validateInput = validateUserInput
  avoidCars = arg.avoidCars or 'off'

  if noOfLaps > 1 and wpList[2] and wpList[1] == wpList[#wpList] then
    race = true
  end

  speedList = arg.wpSpeeds or {}
  setSpeed(arg.routeSpeed)
  setSpeedMode(arg.routeSpeedMode)

  driveInLane(arg.driveInLane)

  setAggressionExternal(arg.aggression)
  stateChanged()
end

local function spanMap(cutOffDrivability)
  M.cutOffDrivability = cutOffDrivability or 0
  setState({mode = 'span'})
  stateChanged()
end

local function setCutOffDrivability(drivability)
  M.cutOffDrivability = drivability or 0
  stateChanged()
end

local function onDeserialized(v)
  setState(v)
  stateChanged()
end

local function dumpCurrentRoute()
  dump(currentRoute)
end

local function dumpParameters()
  dump(parameters)
end

local function startRecording()
  M.mode = 'script'
  scriptai = require("scriptai")
  scriptai.startRecording()
  M.updateGFX = scriptai.updateGFX
end

local function stopRecording()
  M.mode = 'disabled'
  scriptai = require("scriptai")
  local script = scriptai.stopRecording()
  M.updateGFX = scriptai.updateGFX
  return script
end

local function startFollowing(...)
  M.mode = 'script'
  scriptai = require("scriptai")
  scriptai.startFollowing(...)
  M.updateGFX = scriptai.updateGFX
end

local function scriptStop(...)
  M.mode = 'disabled'
  scriptai = require("scriptai")
  scriptai.scriptStop(...)
  M.updateGFX = scriptai.updateGFX
end

local function scriptState()
  scriptai = require("scriptai")
  return scriptai.scriptState()
end

local function setScriptDebugMode(mode)
  scriptai = require("scriptai")
  if mode == nil or mode == 'off' then
    M.debugMode = 'all'
    M.debugDraw = nop
    return
  end

  M.debugDraw = debugDraw
  scriptai.debugMode = mode
end

local function isDriving()
  return M.updateGFX == updateGFX or (scriptai ~= nil and scriptai.isDriving())
end

local function logDataTocsv()
  if not misc.csvFile then
    print('Started Logging Data')
    misc.csvFile = require('csvlib').newCSV("time", "posX", "posY", "posZ", "speed", "ax", "throttle", "brake", "steering")
    misc.time = 0
  else
    misc.time = misc.time + dt
  end
  misc.csvFile:add(misc.time, aiPos.x, aiPos.y, aiPos.z, aiSpeed, -sensors.gy, lastCommand.throttle, lastCommand.brake, lastCommand.steering)
end

local function writeCsvFile(name)
  if misc.csvFile then
    print('Writting Data to CSV.')
    misc.csvFile:write(name)
    misc.csvFile = nil
    misc.time = nil
    print('Done')
  else
    print('No data to write')
  end
end

local function startStopDataLog(name)
  if misc.logData == nop then
    print('Initialized Data Log')
    misc.logData = logDataTocsv
  else
    print('Stopped Logging Data')
    misc.logData = nop
    writeCsvFile(name)
  end
end

-- public interface
M.driveInLane = driveInLane
M.stateChanged = stateChanged
M.reset = reset
M.setMode = setMode
M.toggleTrafficMode = toggleTrafficMode
M.setAvoidCars = setAvoidCars
M.setTarget = setTarget
M.setPath = setPath
M.setSpeed = setSpeed
M.setSpeedMode = setSpeedMode
M.setParameters = setParameters
M.dumpParameters = dumpParameters
M.setVehicleDebugMode = setVehicleDebugMode
M.setState = setState
M.getState = getState
M.debugDraw = nop
M.driveUsingPath = driveUsingPath
M.setAggressionMode = setAggressionMode
M.setAggression = setAggressionExternal
M.onDeserialized = onDeserialized
M.setTargetObjectID = setTargetObjectID
M.laneChange = laneChange
M.setStopPoint = setStopPoint
M.dumpCurrentRoute = dumpCurrentRoute
M.spanMap = spanMap
M.setCutOffDrivability = setCutOffDrivability
M.resetLearning = resetLearning
M.isDriving = isDriving
M.startStopDataLog = startStopDataLog

-- scriptai
M.startRecording = startRecording
M.stopRecording = stopRecording
M.startFollowing = startFollowing
M.stopFollowing = scriptStop
M.scriptStop = scriptStop
M.scriptState = scriptState
M.setScriptDebugMode = setScriptDebugMode
return M
