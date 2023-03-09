--- @meta
--- @module 'BeamEngine'

--- @class BeamEngine
BeamEngine = {}

--- @param id number The ID to assign to the object.
--- @param path string The path to the object.
--- @param opts string The options to pass to the object.
--- @param pos vec3 The position to spawn the object at.
function BeamEngine:spawnObject(id, path, opts, pos) end

--- @param id number The ID of the object.
--- @param bundle string The bundle to spawn the object from.
--- @param opts string The options to pass to the object.
--- @param pos vec3 The position to spawn the object at.
function BeamEngine:spawnObject2(id, bundle, opts, pos) end

function BeamEngine:deleteAllObjects() end

--- @return number slots
function BeamEngine:getSlotCount() end

--- @param slot number
--- @return obj slot
function BeamEngine:getSlot(slot) end

--- @return boolean unstable
function BeamEngine:instabilityDetected() end

--- @param enabled boolean
function BeamEngine:setDynamicCollisionEnabled(enabled) end

--- Updates the physics engine.
--- @vararg number
function BeamEngine:update(...) end

--- Initializes and returns a new BeamEngine instance.
--- @param physicsFps number Max physics FPS.
--- @return BeamEngine
function initBeamEngine(physicsFps) end
