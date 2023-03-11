--[=[
<1>{ {}, {}, <2>{ {
      replicating = <function 1>
    }, {}, <3>{ {
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
    ___type = "static_class<SceneObject>",
    __call = <function 6>,
    __index = <function 5>,
    __newindex = <function 7>,
    getDefaultAddGroup = <function 8>,
    <metatable> = <table 2>
  },
  ___type = "static_class<DecalRoad>",
  __call = <function 12>,
  __index = <function 5>,
  __newindex = <function 7>,
  <metatable> = <table 1>
}
]=]

--- @meta

--- @class DecalRoad: SceneObject
--- @field ___type 'static_class<DecalRoad>'
local DecalRoad = {}

--- Call this table as a function to create a new DecalRoad object.
--- @return DecalRoad
function DecalRoad:__call() end

--- Returns the index of the given DecalRoad object.
--- @param self DecalRoad
--- @param index string
--- @return any
function DecalRoad:__index(index) end

--- Sets the given index of the given DecalRoad object to the given value.
--- @param self DecalRoad
--- @param index string
--- @param value any
function DecalRoad:__newindex(index, value) end
