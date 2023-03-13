--[[
<1>{ {
    motionBlurAllVehiclesEnabled = <function 1>,
    motionBlurPlayerVehiclesEnabled = <function 2>
  }, {
    motionBlurAllVehiclesEnabled = <function 3>,
    motionBlurPlayerVehiclesEnabled = <function 4>
  }, <2>{ {}, {}, <3>{ {}, {}, <4>{ {}, {}, <5>{ {
            replicating = <function 5>,
            replicationEnabled = <function 6>
          }, {
            replicating = <function 7>,
            replicationEnabled = <function 8>
          }, <6>{ <7>{
              ___type = "static_class<ConsoleObject>",
              __index = <function 9>
            },
            ___type = "static_class<ConsoleObject>",
            __index = <table 7>,
            <metatable> = <table 6>
          },
          ___type = "static_class<SimObject>",
          __call = <function 10>,
          __index = <function 9>,
          __newindex = <function 11>,
          getDefaultAddGroup = <function 12>,
          setDefaultAddGroup = <function 13>,
          setForcedId = <function 14>,
          setSerializeForEditor = <function 15>,
          <metatable> = <table 5>
        },
        ___type = "static_class<SceneObject>",
        __call = <function 10>,
        __index = <function 9>,
        __newindex = <function 11>,
        <metatable> = <table 4>
      },
      ___type = "static_class<GameBase>",
      __call = <function 16>,
      __index = <function 9>,
      __newindex = <function 11>,
      <metatable> = <table 3>
    },
    ___type = "static_class<ShapeBase>",
    __call = <function 17>,
    __index = <function 9>,
    __newindex = <function 11>,
    <metatable> = <table 2>
  },
  ___type = "static_class<BeamNGVehicle>",
  __call = <function 18>,
  __index = <function 9>,
  __newindex = <function 11>,
  <metatable> = <table 1>
}
]]

--- @meta

--- @class BeamNGVehicle : ShapeBase
--- @field ___type 'static_class<BeamNGVehicle>'
--- @field motionBlurAllVehiclesEnabled boolean
--- @field motionBlurPlayerVehiclesEnabled boolean
local BeamNGVehicle = {}

--- Call this table as a function to create a new BeamNGVehicle object.
--- @return SimObject
function BeamNGVehicle:__call() end

--- Returns the index of the given BeamNGVehicle object.
--- @param self BeamNGVehicle
--- @param index string
--- @return any
function BeamNGVehicle:__index(index) end

--- Sets the index of the given BeamNGVehicle object.
--- @param self BeamNGVehicle
--- @param index string
--- @param value any
function BeamNGVehicle:__newindex(index, value) end
