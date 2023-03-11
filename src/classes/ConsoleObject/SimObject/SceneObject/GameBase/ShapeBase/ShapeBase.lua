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
    ___type = "static_class<GameBase>",
    __call = <function 12>,
    __index = <function 5>,
    __newindex = <function 7>,
    <metatable> = <table 2>
  },
  ___type = "static_class<ShapeBase>",
  __call = <function 13>,
  __index = <function 5>,
  __newindex = <function 7>,
  <metatable> = <table 1>
}
]=]

--- @meta

--- @class ShapeBase: GameBase
--- @field ___type 'static_class<ShapeBase>'
local ShapeBase = {}

--- Call this table as a function to create a new ShapeBase object.
--- @return ShapeBase
function ShapeBase:__call() end

--- Returns the index of the given ShapeBase object.
--- @param self ShapeBase
--- @param index string
--- @return any
function ShapeBase:__index(index) end

--- Sets the value of the given ShapeBase object.
--- @param self ShapeBase
--- @param index string
--- @param value any
function ShapeBase:__newindex(index, value) end
