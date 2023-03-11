--[=[
<1>{ {}, {}, <2>{ {}, {}, <3>{ {
        replicating = <function 1>
      }, {}, <4>{ {
          replicating = <function 1>,
          replicationEnabled = <function 2>
        }, {
          replicating = <function 3>,
          replicationEnabled = <function 4>
        }, <5>{ <6>{
            ___type = "static_class<ConsoleObject>",
            __index = <function 5>
          },
          ___type = "static_class<ConsoleObject>",
          __index = <table 6>,
          <metatable> = <table 5>
        },
        ___type = "static_class<SimObject>",
        __call = <function 6>,
        __index = <function 5>,
        __newindex = <function 7>,
        getDefaultAddGroup = <function 8>,
        setDefaultAddGroup = <function 9>,
        setForcedId = <function 10>,
        setSerializeForEditor = <function 11>,
        <metatable> = <table 4>
      },
      ___type = "static_class<SceneObject>",
      __call = <function 6>,
      __index = <function 5>,
      __newindex = <function 7>,
      getDefaultAddGroup = <function 8>,
      <metatable> = <table 3>
    },
    ___type = "static_class<DecalRoad>",
    __call = <function 12>,
    __index = <function 5>,
    __newindex = <function 7>,
    <metatable> = <table 2>
  },
  ___type = "static_class<AIPath>",
  __call = <function 13>,
  __index = <function 5>,
  __newindex = <function 7>,
  <metatable> = <table 1>
}
]=]

--- @meta

--- @class AIPath: DecalRoad
--- @field ___type 'static_class<AIPath>'
local AIPath = {}

--- Call this table as a function to create a new AIPath object.
--- @return AIPath
function AIPath:__call() end

--- Returns the index of the given AIPath object.
--- @param self AIPath
--- @param index number
--- @return any
function AIPath:__index(index) end

--- Sets the value of the given AIPath object.
--- @param self AIPath
--- @param index number
--- @param value any
function AIPath:__newindex(index, value) end
