-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local script = {}
local inScript = nil

local time = 0
local scriptTime = 0
local prevDirPoint = nil
local prevVel = 0
local prevAccel = 0
local aiPos = vec3(0, 0, 0)
local aiVel = vec3(0, 0, 0)
local aiSpeed = 0
local targetPos = vec3(0, 0, 0)
local aiDirVec = vec3(0, 0, 0)
local followInitCounter = 0
local targetLength = 1
local initConditions = {}
local posError = 0

local loopCounter = 0
local loopType = "alwaysReset"

local speedDiffSmoother = newTemporalSmoothingNonLinear(math.huge, 0.3)

local min, max, abs, sqrt = math.min, math.max, math.abs, math.sqrt

local function velAccelFrom2dist(l1, l2, t1, t2)
  if t1 == t2 and t2 == 0 then
    return 0, 0
  end
  local t1s, t2s = square(t1), square(t2)
  local denom = 1 / (t1s * t2 - t1 * t2s)
  return (l2 * t1s - l1 * t2s) * denom, 2 * (l1 * t2 - l2 * t1) * denom
end

local function driveCar(steering, throttle, brake, parkingbrake)
  input.event("steering", clamp(-steering, -1, 1), 1)
  input.event("throttle", clamp(throttle, 0, 1), 2)
  input.event("brake", clamp(brake, 0, 1), 2)
  input.event("parkingbrake", clamp(parkingbrake, 0, 1), 2)
end

local function calculateTarget()
  local scriptLen = #script

  if scriptLen >= 2 then
    local p1, p2 = vec3(script[1]), vec3(script[2])
    local prevPos = linePointFromXnorm(p1, p2, clamp(aiPos:xnormOnLine(p1, p2), 0, 1))

    for i = 2, scriptLen do
      local curPos = vec3(script[i])
      local diff = curPos - prevPos
      local diffLen = diff:length()
      if diffLen >= targetLength then
        targetPos = prevPos + diff:normalized() * targetLength
        return
      end
      targetLength = targetLength - diffLen
      prevPos = curPos
    end
  end

  targetPos = vec3(script[scriptLen])
end

local function updateGFXrecord(dt)
  local pos = obj:getFrontPosition()
  local scriptLen = #script

  if scriptLen >= 2 then
    local s0, s1 = script[scriptLen], script[scriptLen - 1]
    local p0, p1 = vec3(s0), vec3(s1)

    local posline
    if prevDirPoint ~= nil then
      posline = linePointFromXnorm(prevDirPoint, p1, pos:xnormOnLine(prevDirPoint, p1))
    else
      posline = linePointFromXnorm(p0, p1, pos:xnormOnLine(p0, p1))
    end

    local pospjlen = (pos - posline):projectToOriginPlane(obj:getDirectionVectorUp()):squaredLength()

    if pospjlen < 0.01 then
      local t2 = time - s1.t
      local l2 = pos:distance(p1)
      if not prevDirPoint then
        local l1 = p0:distance(p1)
        prevVel, prevAccel = velAccelFrom2dist(l1, l2, s0.t - s1.t, t2)
        prevDirPoint = p0
      end

      local pl2 = (prevVel + 0.5 * prevAccel * t2) * t2

      if abs(pl2 - l2) < 0.1 then
        scriptLen = scriptLen - 1
      else
        prevDirPoint = nil
      end
    else
      prevDirPoint = nil
    end
  end

  script[scriptLen + 1] = {x = pos.x, y = pos.y, z = pos.z, t = time}
  time = time + dt
end

local function scriptStop(centerWheel, engageParkingbrake)
  if centerWheel == nil then
    centerWheel = true
    engageParkingbrake = true
  end

  if centerWheel then
    driveCar(0, 0, 0, engageParkingbrake and 1 or 0)
  else
    if engageParkingbrake then
      input.event("parkingbrake", 1, 2)
    end
  end

  script = {}
  M.updateGFX = nop
end

local function updateGFXfollow(dt)
  if followInitCounter > 0 then
    followInitCounter = followInitCounter - 1
    return
  end

  local scriptLen = #script
  if scriptLen == 0 then
    M.updateGFX = nop
    return
  end

  aiPos:set(obj:getFrontPosition())
  aiVel:set(obj:getVelocity())
  local aiVelLen = aiVel:length()
  local prevDirVec = aiDirVec
  aiDirVec = obj:getDirectionVector()

  while scriptLen >= 1 do
    local s1, s2 = script[1], script[2] or script[1]
    local p1, p2 = vec3(s1), vec3(s2)
    local xnorm = aiPos:xnormOnLine(p1, p2)
    if (p1:squaredDistance(p2) < 0.0025 and s2.t < time) or aiPos:xnormOnLine(p1, p2) > 1 or (xnorm < 0 and s2.t < time and aiVel:dot(p2 - p1) < 0) then
      table.remove(script, 1)
      scriptLen = scriptLen - 1
    else
      break
    end
  end

  if scriptLen < 3 then
    -- finished
    if loopCounter > 0 then
      loopCounter = loopCounter - 1
    end

    if loopCounter ~= 0 then
      M.startFollowing(inScript, inScript.loopTimeOffset, loopCounter, loopType)
      return
    end

    if scriptLen == 0 then
      ai.stopFollowing()
      return
    end
  end

  calculateTarget()
  local targetPosOnLine = targetPos

  local reqVel
  local timeDiff
  local pbrake
  local s1, s2, s3 = script[1], script[2] or script[1], script[3] or script[2] or script[1]
  local p1, p2, p3 = vec3(s1), vec3(s2), vec3(s3)
  local s1t, s2t, s3t = s1.t, s2.t, s3.t
  local p2p1 = p2 - p1
  local targetaivec = targetPos - aiPos
  local targetai = targetaivec:dot(aiDirVec)
  local posonline = aiPos:xnormOnLine(p1, p2)

  aiSpeed = aiVel:dot(aiDirVec) * sign(targetai)
  local l1 = p2p1:length()
  local l2 = p3:distance(p2) + l1
  local t1 = s2t - s1t
  prevVel, prevAccel = velAccelFrom2dist(l1, l2, t1, s3t - s1t)
  local nextVel = prevVel + prevAccel * t1
  prevVel, nextVel = max(0, prevVel), max(0, nextVel)
  local xnorm = clamp(posonline, 0, 1)
  if prevAccel == 0 then
    scriptTime = lerp(s1t, s2t, xnorm)
  else
    local s = xnorm * l1
    local delta = sqrt(max(0, 2 * prevAccel * s + prevVel * prevVel))
    local ts = (delta - prevVel) / prevAccel
    if ts >= 0 and ts <= t1 then
      scriptTime = ts + s1t
    else
      scriptTime = lerp(s1t, s2t, xnorm)
    end
  end

  reqVel = t1 == 0 and nextVel or lerp(prevVel, nextVel, (scriptTime - s1t) / t1)
  timeDiff = scriptTime - time

  local up = obj:getDirectionVectorUp()
  local left = aiDirVec:cross(up):normalized()
  local turnleft = p2p1:cross(up):normalized()

  local noOversteerCoef = 1
  -- oversteer
  if aiVelLen > 1 then
    local leftVel = left:dot(aiVel)
    if leftVel * left:dot(targetPosOnLine - aiPos) > 0 then
      local dirDiff = -math.asin(left:dot((targetPos - aiPos):normalized()))
      local rotVel = min(1, (prevDirVec:projectToOriginPlane(up):normalized() - aiDirVec):length() * dt * 10000)
      noOversteerCoef = max(0, 1 - abs(leftVel * aiVelLen * 0.05) * min(1, dirDiff * dirDiff * aiVelLen * 6) * rotVel)
    end
  end

  -- deviation
  local tp2
  if targetPosOnLine:xnormOnLine(p1, p2) > 1 then
    tp2 = (targetPosOnLine - p2):normalized():dot(turnleft)
  else
    tp2 = (p3 - p2):normalized():dot(turnleft)
  end

  local carturn = turnleft:dot(left)
  local deviation = (aiPos - p2):dot(turnleft)
  deviation = sign(deviation) * min(5, abs(deviation))
  local reldeviation = sign(tp2) * deviation

  posError = aiPos:distance(linePointFromXnorm(p1, p2, clamp(posonline, 0, 1))) * sign(deviation)

  -- target bending
  local grleft = left:dot(obj:getGravityVector())
  if deviation * grleft > 0 then
    targetPos = targetPosOnLine - left * sign(deviation) * min(5, abs(0.01 * deviation * grleft * aiVelLen * min(1, carturn * carturn)))
  end

  local targetVec = (targetPos - aiPos):normalized()
  local dirDiff = -math.asin(left:dot(targetVec))

  -- understeer
  local steerCoef = reldeviation * min(aiSpeed * aiSpeed, abs(aiSpeed)) * min(1, dirDiff * dirDiff * 4) * 0.2
  local understeerCoef = max(0, -steerCoef) * min(1, abs(aiVel:dot(p2p1:normalized()) * 3))
  local noUndersteerCoef = max(0, 1 - understeerCoef)
  targetLength = max(aiVelLen * 0.65, 3)

  -- reduce time spring when in understeer
  local dif = (reqVel - aiSpeed) * 3 + clamp(-timeDiff * 6, -1, 1.2) * noUndersteerCoef
  if dif <= 0 then
    speedDiffSmoother:set(dif)
  end
  local curthrottle = clamp(speedDiffSmoother:get(dif, dt), -1, 1)

  -- stay put when starting with negative offset
  if curthrottle < 0 and max(aiVelLen, aiSpeed) < 0.5 then
    curthrottle = 0
    pbrake = 1
  else
    pbrake = 0
  end

  -- understeer guard
  if reldeviation < 0 and aiVelLen > 1 then
    curthrottle = curthrottle * noUndersteerCoef
    curthrottle = max(curthrottle, min(0, -1 + understeerCoef * understeerCoef)) -- cut off brake
  else
    if curthrottle > 0 then
      curthrottle = min(1, curthrottle * (1 + abs(deviation))) -- push some more when on the inside of the turn
    end
  end

  local throttle, brake = clamp(curthrottle, 0, 1), clamp(-curthrottle, 0, 1)
  brake = min(1, max(0, brake - 0.1) / (1 - 0.1)) -- reduce brake flutter

  -- print(timeDiff)
  -- print(noUndersteerCoef..','..noOversteerCoef)

  -- wheel speed
  local absAiSpeed = abs(aiSpeed)
  if absAiSpeed > 0.05 then
    if sensors.gz <= 0 then
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
      brake = brake * square(max(0, absAiSpeed - totalSlip) / absAiSpeed)

      -- tcs, oversteer
      throttle = throttle * min(noOversteerCoef, max(0, absAiSpeed - propSlip * propSlip) / absAiSpeed)
    else
      brake = 0
      throttle = 0
    end
  end

  -- reverse
  if targetai < 0 then
    local targetailen = targetaivec:length()
    if targetai / (targetailen + 1e-30) < -0.5 or targetailen < 8 then
      dirDiff = -dirDiff
      throttle, brake = brake, throttle
    end
  end

  if aiSpeed > 4 and aiSpeed < 30 and abs(dirDiff) > 0.8 and brake == 0 then
    pbrake = 1
  end

  driveCar(dirDiff, throttle, brake, pbrake)

  time = time + dt
end

local function startRecording()
  table.clear(script)
  time = 0
  M.updateGFX = updateGFXrecord
  prevDirPoint = nil

  local dir, up = obj:getDirectionVector(), obj:getDirectionVectorUp()
  initConditions.dir = {x = dir.x, y = dir.y, z = dir.z}
  initConditions.up = {x = up.x, y = up.y, z = up.z}
end

local function stopRecording()
  --print(">>> AI.stopRecording")
  M.updateGFX = nop

  if script[1] ~= nil then
    script[1].dir = initConditions.dir
    script[1].up = initConditions.up
  end
  return {path = script}
  -- return script
end

local function startFollowing(_inScript, _timeOffset, _loopCounter, _loopType)
  --print(">>> AI.startFollowing: " .. dumps(inScript))
  -- inScript = testrec
  inScript = _inScript
  if inScript == nil then
    return
  end
  if inScript.path ~= nil then
    script = inScript.path
  else
    script = inScript
  end

  script = deepcopy(script)
  if #script <= 1 then
    return
  end

  loopType = _loopType or "alwaysReset"
  local timeOffset = _timeOffset or inScript.timeOffset
  local startDelay = inScript.startDelay or 0
  local totalLoopCount = inScript.loopCount or 1
  loopCounter = _loopCounter or totalLoopCount

  if timeOffset ~= nil and timeOffset ~= 0 then
    if timeOffset > 0 then
      while script[2] ~= nil and script[2].t < timeOffset do
        table.remove(script, 1)
      end
      if #script >= 2 then
        local s1t = script[1].t
        local sp = linePointFromXnorm(vec3(script[1]), vec3(script[2]), (timeOffset - s1t) / (script[2].t - s1t))
        script[1] = {x = sp.x, y = sp.y, z = sp.z, t = timeOffset}
      end
    end
    for _, s in ipairs(script) do
      s.t = s.t - timeOffset
    end
    if #script <= 1 then
      return
    end
  end
  if startDelay > 0 then
    for _, s in ipairs(script) do
      s.t = s.t + startDelay
    end
  end

  local initDir = script[1].dir
  local initUp = script[1].up

  followInitCounter = 3
  prevVel = 0
  time = 0
  scriptTime = 0
  posError = 0
  speedDiffSmoother:set(0)

  local p1 = vec3(script[1])

  local dir
  local up
  local pos
  if initDir ~= nil then
    dir = vec3(initDir)

    if initUp ~= nil then
      up = vec3(initUp)
    else
      up = mapmgr.surfaceNormalBelow(pos)
    end

    local frontPosRelOrig = obj:getOriginalFrontPositionRelative() -- original relative front position in the vehicle coordinate system (left, back, up)
    local vx = dir * -frontPosRelOrig.y
    local vz = up * frontPosRelOrig.z
    local vy = dir:cross(up) * -frontPosRelOrig.x
    pos = p1 - vx - vz - vy
  else
    local p2
    for i = 2, #script do
      if p1:z0():distance(vec3(script[i]):z0()) > 0.2 then
        p2 = vec3(script[i])
        break
      end
    end

    if p2 ~= nil then
      dir = (p2 - p1):normalized()
      up = mapmgr.surfaceNormalBelow(p1)

      local frontPosRelOrig = obj:getOriginalFrontPositionRelative() -- original relative front position in the vehicle coordinate system (left, back, up)
      local vx = dir * -frontPosRelOrig.y
      local vz = up * frontPosRelOrig.z
      local vy = dir:cross(up) * -frontPosRelOrig.x
      pos = p1 - vx - vz - vy
    end
  end

  if dir ~= nil then
    if loopType == "alwaysReset" or (loopType == "startReset" and loopCounter == totalLoopCount) then
      obj:requestReset(RESET_PHYSICS)
      obj:queueGameEngineLua("be:getObjectByID(" .. tostring(obj:getId()) .. "):resetBrokenFlexMesh()")
      local rot = quatFromDir(dir:cross(up):cross(up), up)
      obj:queueGameEngineLua("be:getObjectByID(" .. obj:getId() .. "):autoplace(false);vehicleSetPositionRotation(" .. obj:getId() .. "," .. pos.x .. "," .. pos.y .. "," .. pos.z .. "," .. rot.x .. "," .. rot.y .. "," .. rot.z .. "," .. rot.w .. ")")
    end
    if controller.mainController then
      controller.mainController.setGearboxMode("arcade")
    end
    wheels.setABSBehavior("arcade")

    M.updateGFX = updateGFXfollow
  end
end

local function debugDraw()
  local debugDrawer = obj.debugDrawProxy

  if M.debugMode == "all" or M.debugMode == "target" then
    if M.updateGFX == updateGFXfollow then
      debugDrawer:drawSphere(0.2, vec3(targetPos), color(0, 0, 255, 255))
    end
  end

  if M.debugMode == "all" or M.debugMode == "path" then
    for _, s in ipairs(script) do
      debugDrawer:drawSphere(0.2, vec3(s), color(255, 0, 0, 255))
    end
  end
end

local function scriptState()
  if M.updateGFX == updateGFXrecord then
    return {status = "recording", time = time}
  elseif M.updateGFX == updateGFXfollow then
    return {status = "following", scriptTime = scriptTime, time = time, endScriptTime = script[#script].t, posError = posError, targetPos = vec3(targetPos), startDelay = (inScript.startDelay or nil)}
  end
  return nil
end

local function isDriving()
  return M.updateGFX == updateGFXfollow
end

M.updateGFX = nop
M.startRecording = startRecording
M.stopRecording = stopRecording
M.startFollowing = startFollowing
M.stopFollowing = scriptStop
M.scriptStop = scriptStop
M.debugDraw = debugDraw
M.scriptState = scriptState
M.isDriving = isDriving
M.debugMode = "all"

return M
