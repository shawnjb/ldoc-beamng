--- @meta
--- @module 'MPHelpers'

--- @class MPHelpers
MPHelpers = {}

--- Returns the vehicle with the given game ID.
--- @param gameID number
--- @return obj
function MPHelpers.getVehicleByGameID(gameID) end

--- Returns the vehicle with the given server ID.
--- @param serverVehicleID string
--- @return obj
function MPHelpers.getVehicleByServerID(serverVehicleID) end

--- Returns the player with the given name.
--- @param name string
--- @return obj
function MPHelpers.getPlayerByName(name) end

--- Returns whether the vehicle with the given ID is owned by the local player.
--- @param vehID number
--- @return boolean
function MPHelpers.isOwn(vehID) end

--- Returns a map of all owned vehicles.
--- @return table<number, obj>
function MPHelpers.getOwnMap() end

--- Sets the ownership of the vehicle with the given ID.
--- @param vehID number
--- @param own boolean
function MPHelpers.setOwn(vehID, own) end

--- Returns a map of all vehicles and their distance to the local player.
--- @return table<number, obj>
function MPHelpers.getDistanceMap() end

--- Returns a map of all vehicle IDs and their game IDs.
--- @return table<number, number>
function MPHelpers.getVehicleMap() end

--- Returns a map of all player names and their IDs.
--- @return table<string, number>
function MPHelpers.getNicknameMap() end

--- Sets whether nicknames are hidden.
--- @param hide boolean
function MPHelpers.hideNicknames(hide) end

--- Sets the prefix of the player with the given name.
--- @param targetName string
--- @param tagSource string
--- @param text string
function MPHelpers.setPlayerNickPrefix(targetName, tagSource, text) end

--- Sets the suffix of the player with the given name.
--- @param targetName string
--- @param tagSource string
--- @param text string
function MPHelpers.setPlayerNickSuffix(targetName, tagSource, text) end

--- Returns a map of all game vehicle IDs and their server IDs.
--- @return table<number, string>
function MPHelpers.getGameVehicleID() end

--- Returns a map of all server vehicle IDs and their game IDs.
--- @return table<string, number>
function MPHelpers.getServerVehicleID() end

--- Saves the default vehicle.
function MPHelpers.saveDefaultRequest() end

--- Spawns the default vehicle.
function MPHelpers.spawnDefaultRequest() end

--- Spawns the vehicle with the given JBeam name.
--- @param jbeamName string
--- @param config table
--- @param colors table
function MPHelpers.spawnRequest(jbeamName, config, colors) end

--- Replaces the vehicle with the given JBeam name.
--- @param jbeamName string
--- @param config table
--- @param colors table
function MPHelpers.replaceRequest(jbeamName, config, colors) end

--- Sends the given beamstate to the vehicle with the given game ID.
--- @param state string
--- @param gameVehicleID number
function MPHelpers.sendBeamstate(state, gameVehicleID) end

--- Applies all queued events.
function MPHelpers.applyQueuedEvents() end

--- Teleports the vehicle with the given name to the player with the given name.
--- @param targetName string
function MPHelpers.teleportVehToPlayer(targetName) end

--- Focuses the camera on the player with the given name.
--- @param targetName string
function MPHelpers.focusCameraOnPlayer(targetName) end

--- Teleports the ground marker to the player with the given name.
--- @param targetName string
function MPHelpers.groundmarkerToPlayer(targetName) end

--- Makes the ground marker follow the player with the given name.
--- @param targetName string
function MPHelpers.groundmarkerFollowPlayer(targetName) end

--- Queries the road node closest to the given position.
--- @param position vec3
--- @param targetName string
function MPHelpers.queryRoadNodeToPosition(position, targetName) end

--- Sends a vehicle edit request.
function MPHelpers.sendVehicleEdit() end

--- Called when our VE files load and the vehicle is ready.
function MPHelpers.onVehicleReady() end

return MPHelpers
