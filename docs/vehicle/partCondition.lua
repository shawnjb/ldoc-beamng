-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local min = math.min
local max = math.max

local hasExecutedInitWork = false

local partTypeData = {}
local partOdometerAbsoluteBaseValues = {}
local partOdometerRelativeStartingValues = {}
local paintOdometerAbsoluteBaseValues = {}
local paintOdometerRelativeStartingValues = {}

local lastAppliedPartConditions = {}
local hasSetPartCondition = {}

local savedConditionSnapshots = {}
local resetSnapshotKey

local rootPartName

local function createConditionSnapshot(snapshotKey)
  local snapshotData = M.getConditions()
  if not snapshotData or not snapshotKey then
    log("E", "partCondition.createConditionSnapshot", "No snapshot data or no key, cannot create snapshot with key: " .. snapshotKey)
    return
  end

  savedConditionSnapshots[snapshotKey] = snapshotData
end

local function applyConditionSnapshot(snapshotKey)
  if not snapshotKey then
    log("E", "", "No key provided, cannot create snapshot...")
    return
  end
  local snapshotData = savedConditionSnapshots[snapshotKey]
  if not snapshotData then
    log("E", "partCondition.applyConditionSnapshot", "No snapshot data found, cannot apply snapshot with key: " .. snapshotKey)
    return
  end

  hasSetPartCondition = {}
  M.initConditions(snapshotData)
end

local function deleteConditionSnapshots()
  savedConditionSnapshots = {}
  resetSnapshotKey = nil
end

local function setResetSnapshotKey(snapshotKey)
  resetSnapshotKey = snapshotKey
end

local function lookForPowertrainClues(partName, partData)
  local partTypeTags
  for k, v in pairs(partData) do
    if type(v) == "table" then
      if k == "powertrain" then
        local previousPartOrigin
        for i = 2, #v do
          if v[i].partOrigin then
            previousPartOrigin = v[i].partOrigin
          else
            if type(v) == "table" and #v[i] > 1 then
              local deviceType = v[i][1]
              local deviceName = v[i][2]
              local devicePartName = partName
              if previousPartOrigin then
                devicePartName = previousPartOrigin
              end
              partTypeTags = partTypeTags or {}
              partTypeTags[devicePartName] = partTypeTags[devicePartName] or {}
              table.insert(partTypeTags[devicePartName], "powertrainDevice:" .. deviceName)
            --print(string.format("%s -> %s:%s", devicePartName, deviceType, deviceName))
            end
          end
        end
      elseif k == "energyStorage" then
        local previousPartOrigin
        for i = 2, #v do
          if v[i].partOrigin then
            previousPartOrigin = v[i].partOrigin
          else
            if type(v) == "table" and #v[i] > 1 then
              local storageType = v[i][1]
              local storageName = v[i][2]
              local storagePartName = partName
              if previousPartOrigin then
                storagePartName = previousPartOrigin
              end
              partTypeTags = partTypeTags or {}
              partTypeTags[storagePartName] = partTypeTags[storagePartName] or {}
              table.insert(partTypeTags[storagePartName], "energyStorage:" .. storageName)
            --print(string.format("%s -> %s:%s", storagePartName, storageType, storageName))
            end
          end
        end
      else
        if v.radiatorArea and not v.inertia then --look for the radiator part
          --print(string.format("%s -> %s:%s", partName, k, "radiator"))
          partTypeTags = partTypeTags or {}
          partTypeTags[partName] = partTypeTags[partName] or {}
          table.insert(partTypeTags[partName], string.format("powertrainDevice:%s:%s", k, "radiator"))
        elseif v.torqueModExhaust and not v.inertia then --look for the exhaust part
          --print(string.format("%s -> %s:%s", partName, k, "exhaust"))
          partTypeTags = partTypeTags or {}
          partTypeTags[partName] = partTypeTags[partName] or {}
          table.insert(partTypeTags[partName], string.format("powertrainDevice:%s:%s", k, "exhaust"))
        elseif v.turbocharger and not v.inertia then
          partTypeTags = partTypeTags or {}
          partTypeTags[partName] = partTypeTags[partName] or {}
          table.insert(partTypeTags[partName], string.format("powertrainDevice:%s:%s", k, "turbocharger"))
        --print(string.format("%s -> %s:%s", partName, k, "turbocharger"))
        end
      end
    end
  end

  return partTypeTags
end

local function lookForFlexbodyClues()
  local partTypeTags = {}
  for _, flexbody in pairs(v.data.flexbodies) do
    if flexbody.partOrigin then
      partTypeTags[flexbody.partOrigin] = partTypeTags[flexbody.partOrigin] or {}
      table.insert(partTypeTags[flexbody.partOrigin], string.format("jbeam:flexbody:%s", flexbody.mesh))
    end
  end
  return partTypeTags
end

local function lookForJbeamClues()
  local partTypeTags = {}
  local didFindClues = false
  local beamsPerPart = {}
  for _, beam in pairs(v.data.beams) do
    if beam.partOrigin then
      local partName = beam.partOrigin
      if beam.beamDampRebound and beam.beamDampRebound > 0 and beam.beamDampFast and beam.beamDampVelocitySplit and beam.beamDampVelocitySplit < math.huge and beam.beamDampReboundFast then
        didFindClues = true
        partTypeTags[partName] = partTypeTags[partName] or {}
      --table.insert(partTypeTags[partName], string.format("jbeam:damper:%s", beam.name))
      end
      if beam.breakGroup then
        didFindClues = true
        partTypeTags[partName] = partTypeTags[partName] or {}
        local breakGroups = type(beam.breakGroup) == "table" and beam.breakGroup or {beam.breakGroup}
        for _, breakGroup in ipairs(breakGroups) do
          table.insert(partTypeTags[partName], string.format("jbeam:breakGroup:%s", breakGroup))
        end
      end
      beamsPerPart[beam.partOrigin] = beamsPerPart[beam.partOrigin] or {beamCids = {}, deformableBeams = 0, breakableBeams = 0}
      --exclude support beams
      if beam.beamType ~= 7 and beam.beamDeform < math.huge and beam.beamDeform < beam.beamStrength then
        beamsPerPart[beam.partOrigin].deformableBeams = (beamsPerPart[beam.partOrigin].deformableBeams or 0) + 1
      end
      if beam.beamType ~= 7 and beam.beamStrength < math.huge then
        beamsPerPart[beam.partOrigin].breakableBeams = (beamsPerPart[beam.partOrigin].breakableBeams or 0) + 1
      end
      table.insert(beamsPerPart[beam.partOrigin].beamCids, beam.cid)
    end
  end

  for partName, partData in pairs(beamsPerPart) do
    if partData.deformableBeams > 0 or partData.breakableBeams > 0 then
      didFindClues = true
      partTypeTags[partName] = partTypeTags[partName] or {}
      for _, beamCid in ipairs(partData.beamCids) do
        if v.data.beams[beamCid] and v.data.beams[beamCid].beamType ~= 7 then --exclude support beams (type 7 -> bdebug.lua)
          table.insert(partTypeTags[partName], string.format("jbeam:beamDamage:%d", beamCid))
        end
      end
    end
  end

  return didFindClues and partTypeTags or nil
end

local function preparePartData()
  for k, v in pairs(v.data.activeParts) do
    local partName = k
    local powertrainClues = lookForPowertrainClues(partName, v)
    if powertrainClues then
      for part, types in pairs(powertrainClues) do
        partTypeData[part] = partTypeData[part] or {}
        for _, partType in pairs(types) do
          table.insert(partTypeData[part], partType)
        end
      end
    end
  end

  local flexbodyClues = lookForFlexbodyClues()
  if flexbodyClues then
    for part, types in pairs(flexbodyClues) do
      partTypeData[part] = partTypeData[part] or {}
      for _, partType in pairs(types) do
        table.insert(partTypeData[part], partType)
      end
    end
  end

  local jbeamClues = lookForJbeamClues()
  if jbeamClues then
    for part, types in pairs(jbeamClues) do
      partTypeData[part] = partTypeData[part] or {}
      for _, partType in pairs(types) do
        table.insert(partTypeData[part], partType)
      end
    end
  end

  for partName, types in pairs(partTypeData) do
    local deduplication = {}
    for _, partType in pairs(types) do
      deduplication[partType] = true
    end
    partTypeData[partName] = {}
    for partType, _ in pairs(deduplication) do
      table.insert(partTypeData[partName], partType)
    end
  end
  --dump(partTypeData)
  hasExecutedInitWork = true
end

local function getRootPartOdometerValue()
  if not rootPartName then
    for _, part in pairs(v.data.activeParts) do
      if part.slotType == "main" then
        rootPartName = part.partName
        break
      end
    end
  end

  local spawnTimeOdometer = partOdometerAbsoluteBaseValues[rootPartName] or 0
  local odometer = spawnTimeOdometer + max(extensions.odometer.getRelativeRecording() - (partOdometerRelativeStartingValues[rootPartName] or 0), 0)
  return odometer
end

local function getRootPartTripValue()
  if not rootPartName then
    for _, part in pairs(v.data.activeParts) do
      if part.slotType == "main" then
        rootPartName = part.partName
        break
      end
    end
  end

  local trip = max(extensions.odometer.getRelativeRecording() - (partOdometerRelativeStartingValues[rootPartName] or 0), 0)
  return trip
end

local function setPartMeshColor(partName, color1R, color1G, color1B, color1A, color2R, color2G, color2B, color2A, color3R, color3G, color3B, color3A)
  for _, partType in ipairs(partTypeData[partName] or {}) do
    local split = split(partType, ":")
    if split[1] == "jbeam" and split[2] == "flexbody" then
      --TODO improve interface to GE for setting mesh colors
      obj:queueGameEngineLua(string.format("be:getObjectByID(%d):setMeshColor(%q, ColorI(%d,%d,%d,%d), ColorI(%d,%d,%d,%d), ColorI(%d,%d,%d,%d))", objectId, split[3], color1R, color1G, color1B, color1A, color2R, color2G, color2B, color2A, color3R, color3G, color3B, color3A))
    end
  end
end

local function getAgedColors(colors, paintOdometer)
  -- paint wear settings
  local brokenPaintKms = 800000 -- kms to reach maximum paint wear (since last painted)
  local lightnessFactor = {}
  lightnessFactor[1] = 0.20 -- how much   red channel is increased at maximum paint wear
  lightnessFactor[2] = 0.30 -- how much green channel is increased at maximum paint wear
  lightnessFactor[3] = 0.30 -- how much  blue channel is increased at maximum paint wear
  local chrominessFactor = 1.00 -- how much    chrominess is lost      at maximum paint wear
  local saturationFactor = 0.05 -- how much    saturation is lost      at maximum paint wear

  -- precompute some data
  local paintWear = clamp(paintOdometer / (brokenPaintKms * 1000), 0, 1) -- paint wear due to mileage
  lightnessFactor[1] = clamp(paintWear * lightnessFactor[1], 0, 1)
  lightnessFactor[2] = clamp(paintWear * lightnessFactor[2], 0, 1)
  lightnessFactor[3] = clamp(paintWear * lightnessFactor[3], 0, 1)
  chrominessFactor = clamp(paintWear * chrominessFactor, 0, 1)
  saturationFactor = clamp(paintWear * saturationFactor, 0, 1)

  -- apply paint wear effects:
  local result = {}
  for c = 1, 3 do
    local oldColor = colors[c]
    if oldColor then
      local color = deepcopy(oldColor.baseColor)
      -- a) decrease chrominess
      --color[4] = color[4] + chrominessFactor * (1 - color[4])

      -- b) decrease overall saturation
      local hsv = RGBtoHSV(vec3(color[1], color[2], color[3]))
      hsv.y = hsv.y * (1 - saturationFactor)
      local rgb = HSVtoRGB(hsv)
      color[1], color[2], color[3] = rgb.x, rgb.y, rgb.z

      -- c) increase lightness, per color
      for i = 1, 3 do
        local increase = lightnessFactor[i] * (1 - color[i])
        color[i] = color[i] + increase
      end
      result[c] = color
    end
  end
  return result
end

local function setPaintCondition(partName, visual)
  local visualState = visual
  if type(visual) == "number" then
    local visualValue = visual
    visualState = {
      paint = {
        odometer = linearScale(visualValue, 1, 0, 0, 800000000) * ((math.random() > 0.5) and 1 or 0.2), --fully bad paint at 800k km
        originalColors = deepcopy(v.config.paints)
      }
    }
  end
  paintOdometerAbsoluteBaseValues[partName] = visualState.paint.odometer --TODO paint
  paintOdometerRelativeStartingValues[partName] = extensions.odometer.getRelativeRecording()

  local colors = getAgedColors(visualState.paint.originalColors, visualState.paint.odometer)

  setPartMeshColor(partName, colors[1][1] * 255, colors[1][2] * 255, colors[1][3] * 255, colors[1][4] * 255, colors[2][1] * 255, colors[2][2] * 255, colors[2][3] * 255, colors[2][4] * 255, colors[3][1] * 255, colors[3][2] * 255, colors[3][3] * 255, colors[3][4] * 255)
end

local function getPaintCondition(partName)
  if not paintOdometerAbsoluteBaseValues[partName] then
    return {odometer = 0, visualValue = 1}, false
  end
  local paintOdometer = (paintOdometerAbsoluteBaseValues[partName] or 0) + max(extensions.odometer.getRelativeRecording() - (paintOdometerRelativeStartingValues[partName] or 0), 0)
  return {odometer = paintOdometer, visualValue = 1}, true
end

local function initCondition(partName, odometer, integrity, visual)
  if hasSetPartCondition[partName] then
    log("E", "partCondition.initCondition", string.format("Trying to set part condition on part %q twice. Unexpected results might follow...", partName))
  end
  lastAppliedPartConditions[partName] = {odometer = odometer, integrity = integrity, visual = visual}
  hasSetPartCondition[partName] = true

  local partTypes = partTypeData[partName] or {}
  powertrain.setPartCondition(partTypes, odometer, integrity, visual)
  energyStorage.setPartCondition(partTypes, odometer, integrity, visual)
  beamstate.setPartCondition(partName, partTypes, odometer, integrity, visual)
  --setPaintCondition(partName, visual)

  partOdometerAbsoluteBaseValues[partName] = odometer
  partOdometerRelativeStartingValues[partName] = extensions.odometer.getRelativeRecording()

  extensions.odometer.startRecording()
end

local function getCondition(partName)
  local partOdometerValue = (partOdometerAbsoluteBaseValues[partName] or 0) + max(extensions.odometer.getRelativeRecording() - (partOdometerRelativeStartingValues[partName] or 0), 0)

  local partData = partTypeData[partName]
  local spawnTimeCondition = lastAppliedPartConditions[partName]
  if not spawnTimeCondition then
    log("E", "partCondition.getCondition", "No spawnTimeCondition found for part: " .. dumps(partName))
    return nil
  end

  local powertrainCondition, canProvidePowertrainCondition = powertrain.getPartCondition(partData)
  local energyStorageCondition, canProvideEnergyStorageCondition = energyStorage.getPartCondition(partData)
  local jbeamCondition, canProvideBeamstateCondition = beamstate.getPartCondition(partName, partData)
  local paintCondition, canProvidePaintCondition = getPaintCondition(partName)

  if canProvidePowertrainCondition or canProvideEnergyStorageCondition or canProvideBeamstateCondition or canProvidePaintCondition then
    local integrityState = {
      powertrain = canProvidePowertrainCondition and powertrainCondition.integrityState or nil,
      energyStorage = canProvideEnergyStorageCondition and energyStorageCondition.integrityState or nil,
      jbeam = canProvideBeamstateCondition and jbeamCondition.integrityState or nil
    }
    local visualState = {
      powertrain = canProvidePowertrainCondition and powertrainCondition.visualState or nil,
      energyStorage = canProvideEnergyStorageCondition and energyStorageCondition.visualState or nil,
      jbeam = canProvideBeamstateCondition and jbeamCondition.visualState or nil,
      paint = canProvidePaintCondition and paintCondition or nil
    }

    local integrityValue = min(powertrainCondition.integrityValue, energyStorageCondition.integrityValue, jbeamCondition.integrityValue)
    local visualValue = min(powertrainCondition.visualValue, energyStorageCondition.visualValue, jbeamCondition.visualValue, paintCondition.visualValue)

    return partOdometerValue, integrityValue, visualValue, integrityState, visualState
  else
    return partOdometerValue, spawnTimeCondition.integrity, spawnTimeCondition.visual, nil, nil
  end
end

local function reset()
  lastAppliedPartConditions = {}
  hasSetPartCondition = {}
  partOdometerAbsoluteBaseValues = {}
  partOdometerRelativeStartingValues = {}
  paintOdometerAbsoluteBaseValues = {}
  paintOdometerRelativeStartingValues = {}

  if not hasExecutedInitWork or not resetSnapshotKey then
    return
  end

  applyConditionSnapshot(resetSnapshotKey)
end

local function getConditions()
  if not hasExecutedInitWork then
    preparePartData()
  end

  if tableIsEmpty(hasSetPartCondition) then
    return false
  end

  local result = {}
  for partName in pairs(v.data.activeParts) do
    xpcall(
      function()
        result[partName] = {getCondition(partName)}
        --log("I", "partCondition.getConditions", string.format("Got condition for partName %25s: ", partName) .. string.sub(serialize(result[partName]), 1, 100))
      end,
      function(err)
        log("E", "partCondition.getConditions", "Unable to get condition for partName " .. dumps(partName) .. ":")
        log("E", "partCondition.getConditions", err)
        log("E", "partCondition.getConditions", debug.traceback())
      end
    )
  end
  return result
end

local function initConditions(partsCondition, fallbackOdometer, fallbackIntegrityValue, fallbackVisualValue)
  if not hasExecutedInitWork then
    preparePartData()
  end

  if not partsCondition then
    log("I", "partCondition.initConditions", "Parts condition not provided for vehicle, assuming fresh vehicle state: " .. dumps(objID))
    for k, _ in pairs(v.data.activeParts) do
      initCondition(k, fallbackOdometer or 0, fallbackIntegrityValue or 1, fallbackVisualValue or 1)
    end
    createConditionSnapshot("reset")
    setResetSnapshotKey("reset")
    return
  end
  for partName in pairs(v.data.activeParts) do
    local odometer, integrity, visual
    local partCondition = partsCondition[partName]
    if partCondition then
      local integrityValue, visualValue, integrityState, visualState
      odometer, integrityValue, visualValue, integrityState, visualState = unpack(partCondition, 1, table.maxn(partCondition))
      integrity = integrityState or integrityValue
      visual = visualState or visualValue
    end

    odometer = odometer or fallbackOdometer or 0
    integrity = integrity or fallbackIntegrityValue or 1
    visual = visual or fallbackVisualValue or 1
    if odometer and integrity --[[and visual--]] then
      initCondition(partName, odometer, integrity, visual)
    else
      log("E", "partCondition.initConditions", "Missing odometer, integrityValue or visualValue for part name " .. dumps(partName) .. " in vehicle " .. dumps(objID) .. ": " .. dumps(partCondition))
    end
  end

  createConditionSnapshot("reset")
  setResetSnapshotKey("reset")
end

--used to make blind calls against partCondition to make sure that everything is inited correctly
local function ensureConditionsInit(fallbackOdometer, fallbackIntegrityValue, fallbackVisualValue)
  if tableIsEmpty(hasSetPartCondition) then
    initConditions(nil, fallbackOdometer, fallbackIntegrityValue, fallbackVisualValue)
  end
end

local function testLoad()
  local data = jsonDecode(readFile("partConditionTest.txt") or "{}")
  hasSetPartCondition = {} --kill data from last init to avoid dual init warning
  M.initConditions(data, 0, 1, 1)
end

local function testSave()
  if tableIsEmpty(hasSetPartCondition) then
    M.initConditions(nil, 812812000, 1, 0.2)
  end
  local data = M.getConditions()

  writeFile("partConditionTest.txt", jsonEncodePretty(data))
end

M.reset = reset

M.getConditions = getConditions
M.initConditions = initConditions
M.ensureConditionsInit = ensureConditionsInit

M.createConditionSnapshot = createConditionSnapshot
M.applyConditionSnapshot = applyConditionSnapshot
M.deleteConditionSnapshots = deleteConditionSnapshots
M.setResetSnapshotKey = setResetSnapshotKey

M.getRootPartOdometerValue = getRootPartOdometerValue
M.getRootPartTripValue = getRootPartTripValue
M.setPartMeshColor = setPartMeshColor

M.testSave = testSave
M.testLoad = testLoad

return M
