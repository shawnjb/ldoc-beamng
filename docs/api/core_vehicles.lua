--- @meta

--- Provides functionality related to vehicles in BeamNG.drive
--- @module "core_vehicles"
core_vehicles = {}

--- Returns the model data for a given model name.
--- @param name string The name of the vehicle model.
--- @return table data A table containing the model data for the given vehicle model.
function core_vehicles.getModel(name) end

--- Returns a list of all vehicle models.
--- @param withDisabled boolean Whether to include disabled models in the list.
--- @return table names A table containing the names of all vehicle models.
function core_vehicles.getModelList(withDisabled) end

--- Spawns a new vehicle with the specified parameters
--- @param spawningPlayer table The player that is spawning the vehicle.
--- @param model string The name of the vehicle model to spawn.
--- @param pos table The position to spawn the vehicle at.
--- @param rot table The rotation to spawn the vehicle with.
--- @return table vehicle The newly spawned vehicle.
function core_vehicles.spawnNewVehicle(spawningPlayer, model, pos, rot) end

--- Replaces the specified vehicle with a new one of the specified model.
--- @param spawningPlayer table The player that is replacing the vehicle.
--- @param model string The name of the vehicle model to spawn.
--- @param oldVehicleId number The ID of the vehicle to replace.
--- @param pos table The position to spawn the new vehicle at.
--- @param rot table The rotation to spawn the new vehicle with.
--- @return table vehicle The newly spawned vehicle.
function core_vehicles.replaceVehicle(spawningPlayer, model, oldVehicleId, pos, rot) end

--- Removes the currently active vehicle for the specified player.
--- @param player table The player whose active vehicle to remove.
function core_vehicles.removeCurrent(player) end

--- Returns the module configuration data for the specified module.
--- @param name string The name of the module.
--- @return table data The configuration data for the specified module.
function core_vehicles.getMod(name) end

--- Sets the text for a vehicle's license plate.
--- @param vehicleId number The ID of the vehicle to set the plate text for.
--- @param text string The text to set for the license plate.
function core_vehicles.setPlateText(vehicleId, text) end

--- Tries to load the specified vehicle configuration or the default vehicle if the specified configuration cannot be loaded.
--- @param vehicleName string The name of the vehicle configuration to load.
--- @return boolean loaded Whether the vehicle was successfully loaded or not.
function core_vehicles.loadMaybeVehicle(vehicleName) end

return core_vehicles
