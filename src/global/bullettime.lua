--[[
{
  get = <function 1>,
  getPause = <function 2>,
  getReal = <function 3>,
  initialTimeScale = 1,
  onDeserialized = <function 4>,
  onSerialize = <function 5>,
  pause = <function 6>,
  pauseSmooth = <function 7>,
  reportSpeed = <function 8>,
  requestValue = <function 9>,
  selectPreset = <function 10>,
  selectionSlot = 12,
  set = <function 11>,
  setInstant = <function 12>,
  simulationSpeed = 1,
  simulationSpeedReal = 1,
  togglePause = <function 13>,
  update = <function 14>
}
]]

--- @meta

--- @class bullettime
--- @field initialTimeScale number
--- @field selectionSlot number
--- @field simulationSpeed number
--- @field simulationSpeedReal number
bullettime = {}

--- Returns the current time scale.
--- @return number
function bullettime.get() end

--- Returns whether the game is paused.
--- @return boolean
function bullettime.getPause() end

--- Returns the current real time scale.
--- @return number
function bullettime.getReal() end

--- Called when the object is deserialized.
function bullettime.onDeserialized() end

--- Called when the object is serialized.
--- @return table
function bullettime.onSerialize() end

--- Pauses the game.
function bullettime.pause() end

--- Smoothly pauses the game.
function bullettime.pauseSmooth() end

--- Reports the current speed.
function bullettime.reportSpeed() end

--- Requests a value from the server.
--- @param value number
function bullettime.requestValue(value) end

--- Selects a preset.
--- @param preset number
function bullettime.selectPreset(preset) end

--- Sets the time scale.
--- @param value number
function bullettime.set(value) end

--- Sets the time scale instantly.
--- @param value number
function bullettime.setInstant(value) end

--- Toggles the pause state.
function bullettime.togglePause() end

--- Updates the time scale.
--- @param dt number
function bullettime.update(dt) end
