--[[
<1>{ {}, {}, <2>{ {
      replicating = <function 1>,
      replicationEnabled = <function 2>
    }, {
      replicating = <function 3>,
      replicationEnabled = <function 4>
    }, <3>{ <4>{
        ___type = "static_class<ConsoleObject>",
        __index = <function 5>
      },
      ___type = "static_class<ConsoleObject>",
      __index = <table 4>,
      <metatable> = <table 3>
    },
    ___type = "static_class<SimObject>",
    __call = <function 6>,
    __index = <function 5>,
    __newindex = <function 7>,
    getDefaultAddGroup = <function 8>,
    setDefaultAddGroup = <function 9>,
    setForcedId = <function 10>,
    setSerializeForEditor = <function 11>,
    <metatable> = <table 2>
  },
  ___type = "static_class<ActionMap>",
  __call = <function 12>,
  __index = <function 5>,
  __newindex = <function 7>,
  addToFilter = <function 13>,
  clearFilters = <function 14>,
  enableInputCommands = <function 15>,
  getInputCommands = <function 16>,
  getList = <function 17>,
  sendInputCommand = <function 18>,
  <metatable> = <table 1>
}
]]

--- @meta

--- @class ActionMap: SimObject
--- @field ___type 'static_class<ActionMap>'
local ActionMap = {}

--- Call this table as a function to create a new ActionMap object.
--- @return ActionMap
function ActionMap:__call() end

--- Returns the index of the given ActionMap object.
--- @param self ActionMap
--- @param index string
--- @return any
function ActionMap:__index(index) end

--- Sets the index of the given ActionMap object.
--- @param self ActionMap
--- @param index string
--- @param value any
function ActionMap:__newindex(index, value) end

--- Adds the given input command to the given filter.
--- @param filter string
--- @param actionName string
--- @param filtered boolean
function ActionMap.addToFilter(filter, actionName, filtered) end

--- Clears all filters.
function ActionMap.clearFilters() end

--- Enables or disables the given input command.
--- @param enabled boolean
function ActionMap.enableInputCommands(enabled) end

--- Returns a list of all input commands.
--- @return table
function ActionMap.getInputCommands() end

--- Returns a list of all ActionMap objects.
--- @return table
function ActionMap.getList() end

--- Sends an input command.
--- @param string string Undocumented. Possibly the input command.
--- @param userdata userdata Undocumented. Possibly the command's related object.
--- @vararg any
--- There is no available documentation for this function.
function ActionMap.sendInputCommand(string, userdata, ...) end
