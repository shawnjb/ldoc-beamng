-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local abs = math.abs

local relativeOdometer = 0

local function onReset()
end

local function updateGFX(dt)
  relativeOdometer = relativeOdometer + abs(electrics.values.wheelspeed or 0) * dt
end

local function startRecording()
  --relativeOdometer = 0
end

local function getRelativeRecording()
  return relativeOdometer
end

local function onExtensionLoaded()
end

-- public interface
M.onReset = onReset
M.updateGFX = updateGFX

M.startRecording = startRecording
M.getRelativeRecording = getRelativeRecording

M.onExtensionLoaded = onExtensionLoaded

return M
