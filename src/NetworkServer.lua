--- @meta
--- @module 'NetworkServer'

--- @class NetworkServer
--- @field receive fun(self: NetworkServer): ...? Receives a message from the network server. Returns nil if no message is available.
local NetworkServer = {}

--- @alias ServerType
--- | '"tcp"' # TCP server.
--- | '"udp"' # UDP server.

--- Creates a new network server.
--- @param type ServerType The type of server to create.
--- @param port number The port to listen on.
--- @return NetworkServer The created network server.
function createNetworkServer(type, port) end
