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
  ___type = "static_class<SceneObject>",
  __call = <function 6>,
  __index = <function 5>,
  __newindex = <function 7>,
  <metatable> = <table 1>
}
]=]

--- @meta

--- @class SceneObject: SimObject
--- @field ___type 'static_class<SceneObject>'
local SceneObject = {}

--- Returns whether the object is replicating or not.
--- @return boolean replicating
function SceneObject:replicating() end

--- Returns whether replication is enabled for this object.
--- @return boolean replicationEnabled
function SceneObject:replicationEnabled() end

--- Returns the default group to add new objects to.
--- @return SceneObject defaultAddGroup
function SceneObject.setDefaultAddGroup() end

--- Sets the forced ID for the object.
--- @param forcedId number
function SceneObject.setForcedId(forcedId) end

--- Sets whether the object should be serialized for the editor.
--- @param serializeForEditor boolean
function SceneObject.setSerializeForEditor(serializeForEditor) end

--- Returns whether the object is a child of the given group.
--- @param group SceneObject
--- @return boolean isChildOfGroup
function SceneObject:isChildOfGroup(group) end

return SceneObject
