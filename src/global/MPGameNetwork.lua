--[[
{
  CallEvent = <function 1>,
  __extensionName__ = "MPGameNetwork",
  __extensionPath__ = "MPGameNetwork",
  __manuallyLoaded__ = true,
  addKeyEventListener = <function 2>,
  connectToLauncher = <function 3>,
  connectionStatus = <function 4>,
  disconnectLauncher = <function 5>,
  getKeyState = <function 6>,
  launcherConnected = <function 7>,
  onKeyStateChanged = <function 8>,
  onUpdate = <function 9>,
  onVehicleReady = <function 10>,
  quitMP = <function 11>,
  send = <function 12>
}
]]

--- @meta
--- @module 'MPGameNetwork'

--- @class MPGameNetwork
--- @field __extensionName__ 'MPGameNetwork'
--- @field __extensionPath__ 'MPGameNetwork'
--- @field __manuallyLoaded__ boolean
MPGameNetwork = {}

--- Adds an event listener for key events.
--- @vararg any
--- @return any
function MPGameNetwork.addKeyEventListener(...) end

--- Connects to the launcher.
--- @vararg any
--- @return any
function MPGameNetwork.connectToLauncher(...) end

--- Returns the connection status.
--- @vararg any
--- @return any
function MPGameNetwork.connectionStatus(...) end

--- Disconnects from the launcher.
--- @vararg any
--- @return any
function MPGameNetwork.disconnectLauncher(...) end

--- Returns the key state.
--- @vararg any
--- @return any
function MPGameNetwork.getKeyState(...) end

--- Returns whether the launcher is connected.
--- @vararg any
--- @return any
function MPGameNetwork.launcherConnected(...) end

--- When a key state changes, this event is called.
--- @vararg any
--- @return any
function MPGameNetwork.onKeyStateChanged(...) end

--- Called when the vehicle is updated.
--- @vararg any
--- @return any
function MPGameNetwork.onUpdate(...) end

--- Called when the vehicle is ready.
--- @vararg any
--- @return any
function MPGameNetwork.onVehicleReady(...) end

--- Quits the multiplayer game.
--- @vararg any
--- @return any
function MPGameNetwork.quitMP(...) end

--- Sends a message to the launcher.
--- @vararg any
--- @return any
function MPGameNetwork.send(...) end
