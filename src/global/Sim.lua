--[[
<1>{
  ___type = "module<Sim>",
  __index = <function 1>,
  __newindex = <function 2>,
  deserializeLineObjects = <function 3>,
  deserializeObjectFromFile = <function 4>,
  deserializeObjectsFromFile = <function 5>,
  deserializeObjectsFromText = <function 6>,
  findObject = <function 7>,
  findObjectById = <function 8>,
  findObjectByIdNoUpcast = <function 9>,
  findObjectByPersistID = <function 10>,
  getDataBlockSet = <function 11>,
  getDecalRoadData = <function 12>,
  getMaterialSet = <function 13>,
  getRootGroup = <function 14>,
  getSFXAmbienceSet = <function 15>,
  getSFXDescriptionSet = <function 16>,
  getSFXEnvironmentSet = <function 17>,
  getSFXParameterGroup = <function 18>,
  getSFXStateSet = <function 19>,
  getSFXTrackSet = <function 20>,
  getSimObjectDerivedClassNames = <function 21>,
  getUniqueName = <function 22>,
  getVerticesOfDecalRoad = <function 23>,
  objectExists = <function 24>,
  objectExistsById = <function 25>,
  serializeObjectToDirectories = <function 26>,
  serializeToLineObjectsFile = <function 27>,
  upcast = <function 28>,
  <metatable> = <table 1>
}
]]

--- @meta
--- @module 'Sim'

--- @class Sim
--- @field ___type 'module<Sim>'
Sim = {}

--- Returns the index of the given Sim object.
--- @param self Sim
--- @param index string
--- @return any
function Sim:__index(index) end

--- Sets the index of the given Sim object.
--- @param self Sim
--- @param index string
--- @param value any
function Sim:__newindex(index, value) end

--- Deserializes a single object from a file.
--- @vararg any
--- @return any
function Sim.deserializeLineObjects(...) end

--- This function is not documented, and may be incorrect.
--- @vararg any
--- @return any
function Sim.deserializeObjectFromFile(...) end

--- Deserializes objects from a file.
--- @vararg any
--- @return any
function Sim.deserializeObjectsFromFile(...) end

--- Deserializes objects from a string.
--- @vararg any
--- @return any
function Sim.deserializeObjectsFromText(...) end

--- Finds an object by name.
--- @vararg any
--- @return any
function Sim.findObject(...) end

--- Finds an object by ID.
--- @vararg any
--- @return any
function Sim.findObjectById(...) end

--- Finds an object by ID without upcasting.
--- @vararg any
--- @return any
function Sim.findObjectByIdNoUpcast(...) end

--- Finds an object by persistent ID.
--- @vararg any
--- @return any
function Sim.findObjectByPersistID(...) end

--- Returns the datablock set.
--- @vararg any
--- @return any
function Sim.getDataBlockSet(...) end

--- Returns the decal road data.
--- @vararg any
--- @return any
function Sim.getDecalRoadData(...) end

--- Returns the material set.
--- @vararg any
--- @return any
function Sim.getMaterialSet(...) end

--- Returns the root group.
--- @vararg any
--- @return any
function Sim.getRootGroup(...) end

--- Returns the SFX ambience set.
--- @vararg any
--- @return any
function Sim.getSFXAmbienceSet(...) end

--- Returns the SFX description set.
--- @vararg any
--- @return any
function Sim.getSFXDescriptionSet(...) end

--- Returns the SFX environment set.
--- @vararg any
--- @return any
function Sim.getSFXEnvironmentSet(...) end

--- Returns the SFX parameter group.
--- @vararg any
--- @return any
function Sim.getSFXParameterGroup(...) end

--- Returns the SFX state set.
--- @vararg any
--- @return any
function Sim.getSFXStateSet(...) end

--- Returns the SFX track set.
--- @vararg any
--- @return any
function Sim.getSFXTrackSet(...) end

--- Returns the derived class names of the given Sim object.
--- @vararg any
--- @return any
function Sim.getSimObjectDerivedClassNames(...) end

--- Returns a unique name.
--- @vararg any
--- @return any
function Sim.getUniqueName(...) end

--- Returns the vertices of the decal road.
--- @vararg any
--- @return any
function Sim.getVerticesOfDecalRoad(...) end

--- Checks if the given object exists.
--- @vararg any
--- @return any
function Sim.objectExists(...) end

--- Checks if the given object exists by ID.
--- @vararg any
--- @return any
function Sim.objectExistsById(...) end

--- Serializes an object to directories.
--- @vararg any
--- @return any
function Sim.serializeObjectToDirectories(...) end

--- Serializes an object to a file.
--- @vararg any
--- @return any
function Sim.serializeToLineObjectsFile(...) end

--- Upcasts the given object.
--- @vararg any
--- @return any
function Sim.upcast(...) end

return Sim
