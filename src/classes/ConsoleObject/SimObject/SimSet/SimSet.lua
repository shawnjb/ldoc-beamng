--[=[
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
  ___type = "static_class<SimSet>",
  __call = <function 12>,
  __index = <function 5>,
  __newindex = <function 7>,
  <metatable> = <table 1>
}
]=]

--- @meta

--- @class SimSet: SimObject
--- @field ___type 'static_class<SimSet>'
local SimSet = {}

--- Call this table as a function to create a new SimSet object.
--- @return SimSet
function SimSet:__call() end

--- Returns the index of the given SimSet object.
--- @param self SimSet
--- @param index string
--- @return any
function SimSet:__index(index) end

--- Sets the index of the given SimSet object.
--- @param self SimSet
--- @param index string
--- @param value any
function SimSet:__newindex(index, value) end
