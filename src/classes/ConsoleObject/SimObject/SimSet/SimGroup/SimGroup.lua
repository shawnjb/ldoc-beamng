--[=[
<1>{ {}, {}, <2>{ {}, {}, <3>{ {
        replicating = <function 1>,
        replicationEnabled = <function 2>
      }, {
        replicating = <function 3>,
        replicationEnabled = <function 4>
      }, <4>{ <5>{
          ___type = "static_class<ConsoleObject>",
          __index = <function 5>
        },
        ___type = "static_class<ConsoleObject>",
        __index = <table 5>,
        <metatable> = <table 4>
      },
      ___type = "static_class<SimObject>",
      __call = <function 6>,
      __index = <function 5>,
      __newindex = <function 7>,
      getDefaultAddGroup = <function 8>,
      setDefaultAddGroup = <function 9>,
      setForcedId = <function 10>,
      setSerializeForEditor = <function 11>,
      <metatable> = <table 3>
    },
    ___type = "static_class<SimSet>",
    __call = <function 12>,
    __index = <function 5>,
    __newindex = <function 7>,
    <metatable> = <table 2>
  },
  ___type = "static_class<SimGroup>",
  __call = <function 13>,
  __index = <function 5>,
  __newindex = <function 7>,
  <metatable> = <table 1>
}
]=]

--- @meta

--- @class SimGroup: SimSet
--- @field ___type 'static_class<SimGroup>'
local SimGroup = {}

--- Call this table as a function to create a new SimGroup object.
--- @return SimGroup
function SimGroup:__call() end

--- Returns the index of the given SimGroup object.
--- @param self SimGroup
--- @param index string
--- @return any
function SimGroup:__index(index) end

--- Sets the index of the given SimGroup object.
--- @param self SimGroup
--- @param index string
--- @param value any
function SimGroup:__newindex(index, value) end
