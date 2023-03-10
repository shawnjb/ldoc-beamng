--- @meta
--- @module 'BeamEngine'

--- The BeamEngine class.
--- @class BeamEngine
BeamEngine = {}

--- Spawns an object, given a path.
--- @param id number The ID to assign to the object.
--- @param path string The path to the object.
--- @param opts string The options to pass to the object.
--- @param pos vec3 The position to spawn the object at.
--- @deprecated
function BeamEngine:spawnObject(id, path, opts, pos) end

--- Spawns an object, given a bundle.
--- @param id number The ID of the object.
--- @param bundle string The bundle to spawn the object from.
--- @param opts string The options to pass to the object.
--- @param pos vec3 The position to spawn the object at.
--- @deprecated
function BeamEngine:spawnObject2(id, bundle, opts, pos) end

--- Deletes all objects in the engine.
--- @deprecated
function BeamEngine:deleteAllObjects() end

--- Returns the number of slots in the engine.
--- @return number slots The number of slots in the engine.
--- @deprecated
function BeamEngine:getSlotCount() end

--- Returns the first slot with a corresponding ID. If no slot is found, nil is returned.
--- @param slot number The ID to search for.
--- @return obj.vehicle slot The slot with the corresponding ID.
--- @deprecated
function BeamEngine:getSlot(slot) end

--- Returns whether an instability has been detected.
--- @return boolean unstable
--- @deprecated
function BeamEngine:instabilityDetected() end

--- Sets the dynamic collision state of the engine.
--- @param enabled boolean
--- @deprecated
function BeamEngine:setDynamicCollisionEnabled(enabled) end

--- Updates the physics engine.
--- @vararg number
--- @deprecated
function BeamEngine:update(...) end

--- Returns the first vehicle with a corresponding ID. If no vehicle is found, nil is returned.
--- @param id number The ID to search for.
--- @return obj.vehicle vehicle
function BeamEngine:getPlayerVehicle(id) end

--- Initializes and returns a new BeamEngine instance.
--- @param physicsFps number Max physics FPS.
--- @return BeamEngine
--- @deprecated
function initBeamEngine(physicsFps) end

--- The engine class.
--- @class Engine
Engine = {}

--- Creates a new BeamEngine, this is used internally.
--- @return BeamEngine engine The new BeamEngine instance.
--- @deprecated
function Engine.createPhysics() end

--- Destroys the current BeamEngine, this is used internally.
--- @deprecated
function Engine.destroyPhysics() end
