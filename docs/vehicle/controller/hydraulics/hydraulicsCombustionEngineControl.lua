-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxiliary"

local rpmToAV = 0.104719755

local raisedIdleAV
local controlledEngine
local relevantPump
local relevantElectrics

local function updateGFXDynamicRaise(dt)
  local activateIdleRaise = false
  local connectPump = false

  for _, electric in ipairs(relevantElectrics) do
    if electrics.values[electric] and electrics.values[electric] ~= 0 then
      activateIdleRaise = true
      connectPump = true
    end
  end

  if electrics.values.wheelspeed > 2 then
    activateIdleRaise = false
  end

  if relevantPump then
    relevantPump:setConnected(connectPump)
  end

  if activateIdleRaise then
    controlledEngine.idleAVOverwrite = raisedIdleAV
    controlledEngine.maxIdleThrottleOverwrite = 1
  else
    controlledEngine.idleAVOverwrite = 0
    controlledEngine.maxIdleThrottleOverwrite = 0
  end
end

local function reset(jbeamData)
end

local function init(jbeamData)
  local mode = jbeamData.mode
  if mode == "electricsRaiseAndConnect" then
    local relevantEngineName = jbeamData.controlledEngine or "mainEngine"
    controlledEngine = powertrain.getDevice(relevantEngineName)
    if not controlledEngine then
      log("E", "hydraulicsIdleRaise.init", "Can't find relevant engine with name: " .. dumps(relevantEngineName))
      return
    end

    local relevantPumpName = jbeamData.relevantPump or "pump1"
    relevantPump = powertrain.getDevice(relevantPumpName)
    if not relevantPump then
      log("E", "hydraulicsIdleRaise.init", "Can't find relevant pump with name: " .. dumps(relevantPumpName))
      return
    end

    relevantElectrics = {}
    local relevantElectricsNames = jbeamData.relevantElectrics or {}
    if type(relevantElectricsNames) == "table" then
      for _, electricsName in pairs(relevantElectricsNames) do
        table.insert(relevantElectrics, electricsName)
      end
    elseif relevantElectricsNames then
      log("E", "hydraulicsIdleRaise.init", "Found wrong type for relevantElectrics, expected table, actual data: " .. dumps(jbeamData.relevantElectrics))
      return
    end

    raisedIdleAV = (jbeamData.raisedIdleRPM or 1800) * rpmToAV
    M.updateGFX = updateGFXDynamicRaise
  end
end

M.init = init
M.reset = reset
M.updateGFX = nop

return M
