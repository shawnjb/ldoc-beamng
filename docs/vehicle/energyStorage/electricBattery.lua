-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max = math.max
local min = math.min

local function updateGFX(storage, dt)
  storage.remainingVolume = storage.initialStoredEnergy > 0 and storage.storedEnergy / 3600000 or 0
  storage.remainingRatio = storage.initialStoredEnergy > 0 and storage.storedEnergy / storage.initialStoredEnergy or 0
end

local function registerDevice(storage, device)
  storage.assignedDevices[device.name] = device
end

local function setRemainingRatio(storage, ratio)
  storage.storedEnergy = storage.initialStoredEnergy * min(max(ratio, 0), 1)
end

local function setPartCondition(storage, odometer, integrity, visual)
  local integrityState = integrity
  if type(integrity) == "number" then
    local integrityValue = integrity
    integrityState = {
      remainingRatio = storage.capacity * integrityValue
    }
  end

  storage:setRemainingRatio(integrityState.remainingRatio or 1)
end

local function getPartCondition(storage)
  local integrityState = {
    remainingRatio = storage.remainingRatio
  }
  local integrityValue = 1

  return integrityValue, integrityState
end

local function reset(storage)
  storage.storedEnergy = storage.startingCapacity * 3600000 --kWh to J
  storage.remainingRatio = storage.initialStoredEnergy > 0 and storage.storedEnergy / storage.initialStoredEnergy or 0
end

local function new(jbeamData)
  local storage = {
    name = jbeamData.name,
    type = jbeamData.type,
    energyType = "electricEnergy",
    assignedDevices = {},
    remainingRatio = 1,
    reset = reset,
    updateGFX = updateGFX,
    registerDevice = registerDevice,
    setRemainingRatio = setRemainingRatio,
    setPartCondition = setPartCondition,
    getPartCondition = getPartCondition
  }

  storage.capacity = jbeamData.batteryCapacity or 0 --kWh
  storage.startingCapacity = jbeamData.startingCapacity or storage.capacity
  storage.storedEnergy = storage.startingCapacity * 3600000 --kWh to J
  storage.energyCapacity = storage.capacity * 3600000 --kWh to J
  storage.remainingVolume = storage.capacity

  storage.initialStoredEnergy = storage.capacity * 3600000 --kWh to J
  storage.remainingRatio = storage.initialStoredEnergy > 0 and storage.storedEnergy / storage.initialStoredEnergy or 0

  storage.jbeamData = jbeamData

  return storage
end

M.new = new

return M
