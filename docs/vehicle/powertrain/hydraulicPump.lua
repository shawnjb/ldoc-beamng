-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.outputPorts = {}
M.deviceCategories = {clutchlike = true, clutch = true, hydraulicPowerSource = true, torqueConsumer = true}

local max = math.max
local abs = math.abs
local sqrt = math.sqrt

local twoPi = math.pi * 2
local invTwoPi = 1 / twoPi

local function updateVelocity(device, dt)
  ---------------- PUMP TYPES ------------------------
  if device.pumpType == "variableDisplacement" then
    --pump type: variable displacement
    --investigate if we need this here or if we can move to the actual hydraulic control logic
    local stallProtection = 1 - clamp((50 - device.inputAV) * 0.02, 0, 1) --0.02 == 1 / 50
    --baseline pressure for dynamic displacement scale
    local baselinePressure = device.pumpWorkingPressure - device.pumpRegulationRange
    device.currentDisplacement = device.pumpMaxDisplacement * device.pumpSmoother:get(linearScale(device.accumulatorPressure, baselinePressure, device.pumpWorkingPressure, 1, 0)) * stallProtection
  elseif device.pumpType == "fixedDisplacement" then
    --pump type: fixed displacement
    device.currentDisplacement = device.pumpMaxDisplacement
  end
  ----------------------------------------------------

  device.inputAV = device.parent.outputAV1 * device.isConnectedCoef

  ------------- Accumulator input -----------------------------
  local accumulatorInFlow = max(0, device.inputAV * invTwoPi * device.currentDisplacement)
  --------------------------------------------------------------

  device.accumulatorInFlow = accumulatorInFlow
  device.accumulatorOilVolume = clamp(device.accumulatorOilVolume + (accumulatorInFlow - device.accumulatorOutFlow) * dt, 0, device.accumulatorMaxVolume * 2)
end

local function updateTorque(device, dt)
  --accumulator
  device.accumulatorPressure = device.pumpWorkingPressure * device.accumulatorOilVolume * device.invAccumulatorMaxVolume

  local torqueDiff = device.inputAV > 0 and (device.accumulatorPressure * device.currentDisplacement * invTwoPi) or 0

  device.torqueDiff = torqueDiff
  device.accumulatorOutFlow = 0

  for _, cylinder in ipairs(device.connectedCylinders) do
    local cylinderFlow, tankFlow = cylinder:update(device.accumulatorPressure, dt)
    device.accumulatorOutFlow = device.accumulatorOutFlow + cylinderFlow + tankFlow
  end

  device.reliefFullyOpenPressure = device.reliefOpeningPressure + device.reliefPressureRange --pre-compute TODO

  --gradually open relief flow as pressure builds, otherwise we get unstable pressure limit
  local reliefPressureScale = linearScale(device.accumulatorPressure, device.reliefOpeningPressure, device.reliefFullyOpenPressure, 0, 1)
  device.reliefFlow = 0.6 * device.reliefValveArea * reliefPressureScale * sqrt(2 * abs(device.accumulatorPressure) * 0.0012) -- 0.6: efficiency, 0.0012: oil density

  electrics.values[device.hydraulicPTOElectricsName] = device.accumulatorPressure
  local remoteAccumulatorFLowIn = electrics.values[device.remoteAccumulatorFlowInElectricsName] or 0 --TODO this only supports a single remote acc
  device.accumulatorOutFlow = device.accumulatorOutFlow + device.reliefFlow + remoteAccumulatorFLowIn
end

local function updateSounds(device, dt)
  local volumeFlowCoef = linearScale(abs(device.accumulatorInFlow), 0.00001, 0.002, 0, 1)
  local volume = device.volumeSmoothing:get(linearScale(device.accumulatorPressure, 1000, 20000000, 0, 1) * volumeFlowCoef, dt)
  local pitch = device.pitchSmoothing:get(linearScale(device.accumulatorInFlow, 0, 0.008, 0, 1), dt)
  obj:setVolumePitchCT(device.pumpSound, volume, pitch, 0, 0)
  --guihooks.graph({"Pressure", device.accumulatorPressure, 55000000, ""}, {"Flow", device.accumulatorInFlow, 0.005, ""}, {"Volume Coef", volumeFlowCoef, 1, ""}, {"Volume", volume, 1, ""}, {"Pitch", pitch, 1, ""})
end

local function setConnected(device, isConnected)
  device.isConnectedCoef = isConnected and 1 or 0
end

local function selectUpdates(device)
  device.velocityUpdate = updateVelocity
  device.torqueUpdate = updateTorque

  if device.isBroken then
  --device.velocityUpdate = disconnectedUpdateVelocity
  --device.torqueUpdate = disconnectedUpdateTorque
  --make sure the virtual mass has the right AV
  --device.virtualMassAV = device.inputAV
  end
end

local function applyDeformGroupDamage(device, damageAmount)
end

local function setPartCondition(device, subSystem, odometer, integrity, visual)
  --device.wearFrictionCoef = linearScale(odometer, 30000000, 1000000000, 1, 1.5)
  local integrityState = integrity
  if type(integrity) == "number" then
    local integrityValue = integrity
  --integrityState = {damageFrictionCoef = linearScale(integrityValue, 1, 0, 1, 50), isBroken = false}
  end

  --device.damageFrictionCoef = integrityState.damageFrictionCoef or 1

  if integrityState.isBroken then
    device:onBreak()
  end
end

local function getPartCondition(device)
  local integrityState = {isBroken = device.isBroken}
  local integrityValue = 1
  if device.isBroken then
    integrityValue = 0
  end
  return integrityValue, integrityState
end

local function validate(device)
  return true
end

local function onBreak(device)
  device.isBroken = true
  selectUpdates(device)
end

local function calculateInertia(device)
  local outputInertia
  local cumulativeGearRatio = 1
  local maxCumulativeGearRatio = 1
  --the pump only has virtual inertia
  outputInertia = device.virtualInertia --some default inertia

  device.cumulativeInertia = outputInertia / device.gearRatio / device.gearRatio
  device.invCumulativeInertia = device.cumulativeInertia > 0 and 1 / device.cumulativeInertia or 0
  device.cumulativeGearRatio = cumulativeGearRatio * device.gearRatio
  device.maxCumulativeGearRatio = maxCumulativeGearRatio * device.gearRatio
end

local function initSounds(device, jbeamData)
  local pumpLoopEvent = jbeamData.pumpLoopEvent or "event:>Vehicle>Hydraulics>Pump_Big"
  device.pumpSound = obj:createSFXSource2(pumpLoopEvent, "AudioDefaultLoop3D", "pumpSound", 0, 1)
  obj:playSFX(device.pumpSound)
  obj:setVolumePitchCT(device.pumpSound, 0, 0, 0, 0)
end

local function resetSounds(device, jbeamData)
end

local function reset(device, jbeamData)
  device.gearRatio = jbeamData.gearRatio or 1
  device.friction = jbeamData.friction or 0
  device.cumulativeInertia = 1
  device.invCumulativeInertia = 1
  device.cumulativeGearRatio = 1
  device.maxCumulativeGearRatio = 1

  device.inputAV = 0
  device.lastInputAV = 0
  device.visualShaftAngle = 0
  device.virtualMassAV = 0
  device.isConnectedCoef = 0

  device.isBroken = false
  device.wearFrictionCoef = 1
  device.damageFrictionCoef = 1

  device.accumulatorOutFlow = 0
  device.accumulatorInFlow = 0

  device[device.outputTorqueName] = 0
  device[device.outputAVName] = 0
  device.accumulatorOilVolume = device.initialAccumulatorOilVolume

  device.pumpSmoother:reset()
  device.volumeSmoothing:reset()
  device.pitchSmoothing:reset()
  device.currentDisplacement = 0

  selectUpdates(device)

  for _, cylinder in ipairs(device.connectedCylinders) do
    cylinder:reset(jbeamData)
  end

  return device
end

local function new(jbeamData)
  local device = {
    deviceCategories = shallowcopy(M.deviceCategories),
    requiredExternalInertiaOutputs = shallowcopy(M.requiredExternalInertiaOutputs),
    outputPorts = shallowcopy(M.outputPorts),
    name = jbeamData.name,
    type = jbeamData.type,
    inputName = jbeamData.inputName,
    inputIndex = jbeamData.inputIndex,
    gearRatio = jbeamData.gearRatio or 1,
    friction = jbeamData.friction or 0,
    dynamicFriction = jbeamData.dynamicFriction or 0,
    wearFrictionCoef = 1,
    damageFrictionCoef = 1,
    cumulativeInertia = 1,
    invCumulativeInertia = 1,
    virtualInertia = 1,
    cumulativeGearRatio = 1,
    maxCumulativeGearRatio = 1,
    isPhysicallyDisconnected = true,
    electricsName = jbeamData.electricsName,
    visualShaftAVName = jbeamData.visualShaftAVName,
    inputAV = 0,
    lastInputAV = 0,
    isConnectedCoef = 0,
    visualShaftAngle = 0,
    virtualMassAV = 0,
    isBroken = false,
    nodeCid = jbeamData.node,
    volumeSmoothing = newTemporalSigmoidSmoothing(5, 2, 2, 5),
    pitchSmoothing = newTemporalSigmoidSmoothing(5, 2, 2, 5),
    reset = reset,
    onBreak = onBreak,
    validate = validate,
    calculateInertia = calculateInertia,
    applyDeformGroupDamage = applyDeformGroupDamage,
    setPartCondition = setPartCondition,
    getPartCondition = getPartCondition,
    initSounds = initSounds,
    resetSounds = resetSounds,
    updateSounds = updateSounds,
    setConnected = setConnected,
    torqueDiff = 0
  }

  device.connectedCylinders = {}

  device.pumpMaxDisplacement = jbeamData.pumpMaxDisplacement or 0.0002
  device.pumpType = jbeamData.pumpType or "variableDisplacement" -- "fixedDisplacement"
  device.pumpRegulationRange = jbeamData.pumpRegulationRange or 10000000
  device.pumpWorkingPressure = jbeamData.pumpWorkingPressure or 25000000
  device.pumpSmoother = newExponentialSmoothing(5)

  device.accumulatorMaxVolume = jbeamData.accumulatorMaxVolume or 0.001
  device.invAccumulatorMaxVolume = 1 / device.accumulatorMaxVolume
  device.initialAccumulatorOilVolume = jbeamData.initialAccumulatorOilVolume or device.accumulatorMaxVolume * 0.9
  device.initialAccumulatorPressure = jbeamData.initialAccumulatorPressure or device.pumpWorkingPressure * 0.9

  device.reliefOpeningPressure = jbeamData.reliefOpeningPressure or device.pumpWorkingPressure * 1.05
  device.reliefPressureRange = jbeamData.reliefPressureRange or 2000000
  device.reliefValveArea = jbeamData.reliefValveArea or 0.00001

  device.currentDisplacement = device.pumpMaxDisplacement
  device.accumulatorPressure = device.initialAccumulatorPressure
  device.accumulatorOilVolume = device.initialAccumulatorOilVolume
  device.accumulatorOutFlow = 0
  device.accumulatorInFlow = 0

  device.hydraulicPTOElectricsName = jbeamData.hydraulicPTOElectricsName or "hydraulicPTO"
  device.remoteAccumulatorFlowInElectricsName = jbeamData.remoteAccumulatorFlowInElectricsName or "remoteAccumulatorFlowIn"

  local hydraulicConsumerFactories = {}
  hydraulicConsumerFactories.hydraulicCylinder = require("powertrain/hydraulicCylinder")
  --hydraulicConsumerFactories.hydraulicRotator = require("powertrain/hydraulicRotator")

  for _, ph in pairs(v.data.powertrainHydros or {}) do
    if ph.connectedPump == device.name then
      local consumerType = ph.type
      local factory = hydraulicConsumerFactories[consumerType]
      local cylinder = factory.new(ph, device)

      table.insert(device.connectedCylinders, cylinder)
    end
  end

  device.outputTorqueName = "outputTorque1"
  device.outputAVName = "outputAV1"
  device[device.outputTorqueName] = 0
  device[device.outputAVName] = 0

  device.mode = "connected"

  device.breakTriggerBeam = jbeamData.breakTriggerBeam
  if device.breakTriggerBeam and device.breakTriggerBeam == "" then
    --get rid of the break beam if it's just an empty string (cancellation)
    device.breakTriggerBeam = nil
  end

  selectUpdates(device)

  return device
end

M.new = new

return M
