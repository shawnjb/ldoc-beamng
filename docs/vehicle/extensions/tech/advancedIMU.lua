-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}

local advancedIMUs = {}         -- The collection of active advanced IMU sensors.
local latestReadings = {}       -- The collection of latest readings for each advanced IMU sensor

-- Send the advanced IMU readings to ge lua.
local function updateAdvancedIMUGFXStep(dtSim, sensorId, isAdHocRequest, adHocRequestId)

  -- Get the latest advanced IMU data from the controller.
  local controller = advancedIMUs[sensorId].controller
  local data = controller.getSensorData()

  -- Draw this advanced IMU sensor, if requested.
  if data.isVisualised == true then
    obj.debugDrawProxy:drawSphere(0.05, data.currentPos, color(0, 255, 0, 255))

    -- Some useful debug visualisation code.
    --obj.debugDrawProxy:drawLine(currentPos + vehicleWorldPos, currentPos + worldForward + vehicleWorldPos, color(0, 0, 255, 255))   -- frame.
    --obj.debugDrawProxy:drawLine(currentPos + vehicleWorldPos, currentPos + worldUp + vehicleWorldPos, color(0, 0, 255, 255))
    --obj.debugDrawProxy:drawLine(currentPos + vehicleWorldPos, currentPos + worldThird + vehicleWorldPos, color(0, 0, 255, 255))
    --obj.debugDrawProxy:drawLine(currentPos, currentPos + normal + vehicleWorldPos, color(255, 0, 0, 255)) -- attachment triangle normal.
    --obj.debugDrawProxy:drawSphere(0.05, node1 + vehicleWorldPos, color(0, 255, 100, 255))   -- the 3 attachment triangle nodes.
    --obj.debugDrawProxy:drawSphere(0.05, node2 + vehicleWorldPos, color(0, 255, 100, 255))
    --obj.debugDrawProxy:drawSphere(0.05, node3 + vehicleWorldPos, color(0, 255, 100, 255))
    --obj.debugDrawProxy:drawLine(currentPos + vehicleWorldPos, node1 + vehicleWorldPos, color(0, 0, 0, 255)) -- sensor to attach nodes lines.
    --obj.debugDrawProxy:drawLine(currentPos + vehicleWorldPos, node2 + vehicleWorldPos, color(0, 0, 0, 255))
    --obj.debugDrawProxy:drawLine(currentPos + vehicleWorldPos, node3 + vehicleWorldPos, color(0, 0, 0, 255))
    --local offset = vec3(0,0,0)--vec3(3, 3, 2)   -- acceleration vectors.
    --local startPoint = currentPos + obj:getPosition() + offset
    --obj.debugDrawProxy:drawSphere(0.01, startPoint, color(0, 0, 255, 255))
    --obj.debugDrawProxy:drawLine(startPoint, startPoint + totalAccel * dtSim, color(255, 0, 0, 255))
  end

  -- If we are not ready to poll this advanced IMU, then increment the timer and leave.
  if not isAdHocRequest and data.timeSinceLastPoll < data.GFXUpdateTime then
    controller.incrementTimer(dtSim)
    return
  end

  -- Send the latest sensor readings from vlua to ge lua.
  local rawReadingsData = { sensorId = sensorId, reading = data.rawReadings }
  obj:queueGameEngineLua(string.format("tech_sensors.updateAdvancedIMULastReadings(%q)", lpack.encode(rawReadingsData)))

  -- If this request is ad-hoc, then we also update the ad-hoc request in ge lua, so that this can be collected later by the user.
  if isAdHocRequest then
    local adHocData = { requestId = adHocRequestId, reading = data.rawReadings }
    obj:queueGameEngineLua(string.format("tech_sensors.updateAdvancedIMUAdHocRequest(%q)", lpack.encode(adHocData)))
  end

  -- Reset the raw readings table, now that the GFX update step has been performed.
  controller.reset()
end

local function create(data)

  -- Create a controller instance for this advanced IMU.
  local decodedData = lpack.decode(data)
  local controllerData = {
    sensorId = decodedData.sensorId,
    GFXUpdateTime = decodedData.GFXUpdateTime,
    physicsUpdateTime = decodedData.physicsUpdateTime,
    nodeIndex1 = decodedData.nodeIndex1,
    nodeIndex2 = decodedData.nodeIndex2,
    nodeIndex3 = decodedData.nodeIndex3,
    u = decodedData.u,
    v = decodedData.v,
    signedProjDist = decodedData.signedProjDist,
    triangleSpaceForward = decodedData.triangleSpaceForward,
    triangleSpaceUp = decodedData.triangleSpaceUp,
    isVisualised = decodedData.isVisualised,
    isUsingGravity = decodedData.isUsingGravity,
    windowWidth = decodedData.windowWidth,
    frequencyCutoff = decodedData.frequencyCutoff,
    isSendImmediately = decodedData.isSendImmediately }

  advancedIMUs[decodedData.sensorId] = {
    data = controllerData,
    controller = controller.loadControllerExternal('tech/advancedIMU', 'advancedIMU' .. decodedData.sensorId, controllerData) }
end

local function remove(sensorId)
  controller.unloadControllerExternal('advancedIMU' .. sensorId)
  advancedIMUs[sensorId] = nil
end

local function setUpdateTime(sensorId, GFXUpdateTime)
  advancedIMUs[sensorId].GFXUpdateTime = GFXUpdateTime
end

local function setIsUsingGravity(data)
  local decodedData = lpack.decode(data)
  advancedIMUs[decodedData.sensorId].controller.setIsUsingGravity(decodedData.isUsingGravity)
end

local function setIsVisualised(data)
  local decodedData = lpack.decode(data)
  advancedIMUs[decodedData.sensorId].controller.setIsVisualised(decodedData.isVisualised)
end

local function adHocRequest(sensorId, requestId)
  updateAdvancedIMUGFXStep(0.0, sensorId, true, requestId)
end

local function cacheLatestReading(sensorId, latestReading)
  if sensorId ~= nil then
    latestReadings[sensorId] = latestReading
  end
end

local function getAdvancedIMUReading(sensorId)
  return latestReadings[sensorId]
end

local function updateGFX(dtSim)
  for sensorId, _ in pairs(advancedIMUs) do
    updateAdvancedIMUGFXStep(dtSim, sensorId, false, nil)
  end
end

local function onVehicleDestroyed(vid)
  for sensorId, _ in pairs(advancedIMUs) do
    if vid == objectId then
      remove(sensorId)
      advancedIMUs[sensorId] = nil
    end
  end
end

-- Public interface:

-- Advanced IMU core API functions.
M.create                                    = create
M.remove                                    = remove
M.adHocRequest                              = adHocRequest
M.cacheLatestReading                        = cacheLatestReading
M.getAdvancedIMUReading                     = getAdvancedIMUReading

-- Advanced IMU property setters.
-- TODO: add getters here too, and expose them to beamNGPy.
M.setUpdateTime                             = setUpdateTime
M.setIsUsingGravity                         = setIsUsingGravity
M.setIsVisualised                           = setIsVisualised

-- Functions triggered by hooks.
M.updateGFX                                 = updateGFX
M.onVehicleDestroyed                        = onVehicleDestroyed

return M