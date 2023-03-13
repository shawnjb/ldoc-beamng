--[[
<1>{ {
    lastDebugFocusPos = <function 1>,
    userLanguage = <function 2>
  }, {
    lastDebugFocusPos = <function 3>,
    userLanguage = <function 4>
  },
  ___type = "class<Lua>",
  __gc = <function 5>,
  __index = <function 6>,
  __newindex = <function 7>,
  dumpStack = <function 8>,
  enableStackTraceFile = <function 9>,
  exec = <function 10>,
  findObjectByIdAsTable = <function 11>,
  findObjectByNameAsTable = <function 12>,
  findObjectsByClassAsTable = <function 13>,
  getAllObjects = <function 14>,
  getFunctionOpcode = <function 15>,
  getOSLanguage = <function 16>,
  getSelectedLanguage = <function 17>,
  getSteamLanguage = <function 18>,
  log = <function 19>,
  queueLuaCommand = <function 20>,
  reloadLanguages = <function 21>,
  requestReload = <function 22>,
  saveFunctionOpcode = <function 23>,
  <metatable> = <table 1>
}
]]

--- @meta

--- The `Lua` class provides functions for interacting with the Lua scripting language. It is a singleton object that is available globally.
--- @class Lua: table
Lua = {}

--- Called when the Lua object is garbage collected.
--- @param self Lua
function Lua:__gc() end

--- Returns the index of the given Lua object.
--- @param self Lua
--- @param index string
--- @return any
function Lua:__index(index) end

--- Sets the index of the given Lua object.
--- @param self Lua
--- @param index string
--- @param value any
function Lua:__newindex(index, value) end

--- Dumps the Lua stack to the console.
--- @param self Lua
function Lua:dumpStack() end

--- Enables the stack trace file.
--- @param self Lua
--- @param enable boolean
function Lua:enableStackTraceFile(enable) end

--- Executes the given Lua code.
--- @param self Lua
--- @param code string
--- @return any
function Lua:exec(code) end

--- Finds an object by ID.
--- @param self Lua
--- @param id number
--- @return table
function Lua:findObjectByIdAsTable(id) end

--- Finds an object by name.
--- @param self Lua
--- @param name string
--- @return table
function Lua:findObjectByNameAsTable(name) end

--- Finds objects by class.
--- @param self Lua
--- @param className string
--- @return table
function Lua:findObjectsByClassAsTable(className) end

--- Returns a list of all objects.
--- @param self Lua
--- @return table
function Lua:getAllObjects() end

--- Returns the opcode of the given function.
--- @param self Lua
--- @param func function
--- @return number
function Lua:getFunctionOpcode(func) end

--- Returns the user's operating system language.
--- @param self Lua
--- @return string
function Lua:getOSLanguage() end

--- Returns the user's selected language.
--- @param self Lua
--- @return string
function Lua:getSelectedLanguage() end

--- Returns the user's Steam language.
--- @param self Lua
--- @return string
function Lua:getSteamLanguage() end

--- Logs the given message.
--- @param self Lua
--- @param message string
function Lua:log(message) end

--- Queues a Lua command.
--- @param self Lua
--- @param command string
function Lua:queueLuaCommand(command) end

--- Reloads the languages.
--- @param self Lua
function Lua:reloadLanguages() end

--- Requests a reload.
--- @param self Lua
function Lua:requestReload() end

--- Saves the opcode of the given function.
--- @param self Lua
--- @param func function
--- @param opcode number
function Lua:saveFunctionOpcode(func, opcode) end
