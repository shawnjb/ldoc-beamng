-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max = math.max
local min = math.min
local abs = math.abs

local function update(cylinder, inputPressure, dt)
  --**VALVE LOGIC**--
  local valveDirection = electrics.values[cylinder.directionElectricsName] or 0
  local valveSign = sign(valveDirection)
  local valveDirectionSmooth = cylinder.valveSmoother:getCapped(valveDirection or 0, dt)
  valveDirection = valveSign * min(abs(valveDirectionSmooth), abs(valveDirectionSmooth))
  --**/VALVE LOGIC**--

  local cylinderArea = (valveSign >= 0 and cylinder.cylinderExtendArea or cylinder.cylinderContractArea)

  cylinder.valveDirection = valveDirection --for logger

  --types of dcv: (directional control valve)
  --float center: A B connect to T, P blocked, so, slipForce = 0, pumpFlow is blocked
  --[WON'T DO] open center: A B and P connect to T, so, slipForce = 0, pumpFlow is free
  --[WON'T DO] tandem center: A B blocked, P connected to T, so slipForce is high, pumpFlow is free
  --closed center: A B P T blocked, so slipForce is high, pumpFlow is blocked
  --drop: like closed but with high enough input, A/B connect to T rather than being blocked
  --[WON'T DO] X regen center: A B connect to P, T is blocked (we prob dont need this, its used to extend cylinders faster than pump flow alone)

  --**VALVE LOGIC**--

  local dragCoef = (cylinder.minimumDragCoef + (1 - valveDirection * valveDirection) * cylinder.dragCoefRange)
  local speedLimit = valveDirection * valveDirection * cylinder.maxSpeed

  local slipForce = cylinder.cylinderReliefPressure * cylinder.invBeamCount * cylinderArea
  local cylinderMaxForce = cylinderArea * cylinder.invBeamCount * inputPressure
  local cylinderForce = cylinderMaxForce * valveSign

  --special hybrid valve type where A & B are conencted to T upon activation (wheeloader bucket drops to ground, also used for one sided cylinder ie dump truck)

  if cylinder.valveType == "drop" then
    --experiment if scaling might be a better option rather than outright using a threshold
    if valveDirection < cylinder.dropInputThreshold then
      slipForce = 0
      cylinderForce = 0
    end
  elseif cylinder.valveType == "float" then
    dragCoef = cylinder.minimumDragCoef
    slipForce = 0
    cylinderForce = cylinderMaxForce * valveDirection
  end
  --**/VALVE LOGIC**--

  --cylinder.cylinderForce = cylinderForce --for logger

  local cylinderForceSmooth = cylinder.cylinderForceSmoother:get(cylinderForce)
  cylinderForce = sign(cylinderForce) * min(abs(cylinderForceSmooth), abs(cylinderForce))

  --cylinder.cylinderForceSmooth = cylinderForce --for logger

  cylinder.cylinderFlow = 0

  --this inner loop is for sets of beams representing 1 cylinder in jbeam
  for _, cid in ipairs(cylinder.beamCids) do
    --actuateBeam(int cid, float force, float speedLimit, float slipForce, float slipSpeedLimit, float minExtend, float maxExtend)
    local previousCylinderVelocity = cylinder.previousBeamVelocities[cid]
    local dragForce = previousCylinderVelocity * previousCylinderVelocity * cylinderArea * cylinder.invBeamCount * dragCoef + cylinder.frictionCoef
    local beamVelocity = obj:actuateBeam(cid, cylinderForce, speedLimit, slipForce, dragForce, 10, cylinder.minExtend, cylinder.maxExtend) --TODO make "slipSpeedLimit"/10 jbeam tunable

    cylinder.cylinderFlow = cylinder.cylinderFlow + beamVelocity * cylinderArea
    cylinder.previousBeamVelocities[cid] = cylinder.beamVelocitySmoothers[cid]:get(beamVelocity)
  end

  local tankFlow = 0
  --**VALVE LOGIC**--
  if cylinder.valveType == "drop" then
    --special hybrid valve type where A & B are conencted to T upon activation (wheeloader bucket drops to ground)
    --experiment if scaling might be a better option rather than outright using a threshold
    if valveDirection < cylinder.dropInputThreshold then
      --set beam velocity to 0 to not affect the acc
      cylinder.cylinderFlow = 0
      tankFlow = 0.1
    end
  end
  --**/VALVE LOGIC**--

  --allow pump to flow when valve is closed but force flow to cylinder as valve opens
  return max(0, cylinder.cylinderFlow * valveSign), tankFlow
end

local function reset(cylinder, jbeamData)
  cylinder.cylinderForceSmoother:reset()
  cylinder.valveSmoother:reset()

  for _, bvs in pairs(cylinder.beamVelocitySmoothers) do
    bvs:reset()
  end
  for k, _ in pairs(cylinder.previousBeamVelocities) do
    cylinder.previousBeamVelocities[k] = 0
  end
end

local function new(cylinderData, pumpDevice)
  local cylinder = {
    connectedPump = pumpDevice,
    name = cylinderData.name,
    valveType = cylinderData.valveType or "closed", --drop, float
    dropInputThreshold = cylinderData.dropInputThreshold or -0.8,
    cylinderReliefPressure = cylinderData.cylinderReliefPressure or 50000000,
    minimumDragCoef = cylinderData.minimumDragCoef or 10000000,
    maximumDragCoef = cylinderData.maximumDragCoef or 100000000,
    frictionCoef = cylinderData.frictionCoef or 0,
    maxSpeed = cylinderData.maxSpeed,
    minExtend = cylinderData.minExtend,
    maxExtend = cylinderData.maxExtend,
    directionElectricsName = cylinderData.directionElectricsName,
    beamCids = {},
    beamVelocitySmoothers = {},
    previousBeamVelocities = {},
    cylinderForceSmoother = newExponentialSmoothing(50),
    valveSmoother = newTemporalSmoothing(10, 10),
    reset = reset,
    update = update
  }

  cylinder.dragCoefRange = max(cylinder.maximumDragCoef - cylinder.minimumDragCoef, 0)

  cylinder.cylinderExtendArea = cylinderData.pistonDiameter * cylinderData.pistonDiameter * 3.1416 / 4
  cylinder.shaftArea = cylinderData.shaftDiameter * cylinderData.shaftDiameter * 3.1416 / 4
  cylinder.cylinderContractArea = cylinder.cylinderExtendArea - cylinder.shaftArea

  for _, bt in pairs(cylinderData.beamTags) do
    if beamstate.tagBeamMap[bt] then
      for _, cid in pairs(beamstate.tagBeamMap[bt]) do
        table.insert(cylinder.beamCids, cid)
        cylinder.beamVelocitySmoothers[cid] = newExponentialSmoothing(500)
        cylinder.previousBeamVelocities[cid] = 0
      end
    end
  end
  cylinder.invBeamCount = 1 / #cylinder.beamCids

  return cylinder
end

M.new = new

return M
