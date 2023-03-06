-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxiliary"

local abs = math.abs

local electricsName
local motorThrottleElectric

local function updateGFX(dt)
  if type(electrics.values[electricsName]) == "number" and abs(electrics.values[electricsName]) > 0 then
    electrics.values[motorThrottleElectric] = 1
  end
end

local function reset(jbeamData)
end

local function init(jbeamData)
  electricsName = jbeamData.controlElectricsName
  motorThrottleElectric = jbeamData.motorThrottleElectricsName
end

M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M
