-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local damageData = {}
local damageDataDelta = {}
local damageTrackerDirtyTimer = 0
local damageTrackerDirtyTime = 1 / 3
local damageUpdateCallbacks = {}

local function updateGFXDirty(dt)
  damageTrackerDirtyTimer = damageTrackerDirtyTimer - dt
  if damageTrackerDirtyTimer <= 0 then
    damageTrackerDirtyTimer = damageTrackerDirtyTime
    M.updateGFX = nop
    guihooks.trigger("DamageData", damageData)
    for _, callback in ipairs(damageUpdateCallbacks) do
      callback(damageData, damageDataDelta)
    end
    damageDataDelta = {}
  end
end

local function setDamage(group, name, value, notifyUI)
  if damageData[group] == nil then
    damageData[group] = {}
  end
  if damageData[group][name] == value then
    return
  end
  damageData[group][name] = value

  damageDataDelta[group] = damageDataDelta[group] or {}
  damageDataDelta[group][name] = value

  if notifyUI then
    local notifyKey = string.format("vehicle.%s.%s.%s", group, name, value)
    guihooks.message(notifyKey, 10, notifyKey)
  end

  M.updateGFX = updateGFXDirty
end

local function getDamage(group, name)
  return damageData[group] and (damageData[group][name] or false) or false
end

local function sendNow()
  M.updateGFX = updateGFXDirty
  damageTrackerDirtyTimer = 0
end

local function willSend()
  return damageTrackerDirtyTimer == damageTrackerDirtyTime and playerInfo.firstPlayerSeated
end

local function registerDamageUpdateCallback(callback)
  if not callback then
    return
  end
  table.insert(damageUpdateCallbacks, callback)
end

local function reset()
  damageData = {}
  damageDataDelta = {}
  damageTrackerDirtyTimer = damageTrackerDirtyTime
  M.updateGFX = nop
end

local function init()
  damageData = {}
  damageDataDelta = {}
  damageUpdateCallbacks = {}
  damageTrackerDirtyTimer = damageTrackerDirtyTime
  M.updateGFX = nop
end

M.init = init
M.reset = reset
M.updateGFX = nop
M.setDamage = setDamage
M.getDamage = getDamage
M.sendNow = sendNow
M.willSend = willSend

M.registerDamageUpdateCallback = registerDamageUpdateCallback

return M
