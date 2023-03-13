--[[
{
  _COPYRIGHT = "Copyright (C) 2005-2017 Kepler Project",
  _DESCRIPTION = "Coroutine Oriented Portable Asynchronous Services",
  _VERSION = "Copas 2.0.2",
  addserver = <function 1>,
  addthread = <function 2>,
  autoclose = true,
  connect = <function 3>,
  dohandshake = <function 4>,
  finished = <function 5>,
  flush = <function 6>,
  gettimeouts = <function 7>,
  handler = <function 8>,
  loop = <function 9>,
  receive = <function 10>,
  receivePartial = <function 11>,
  receivefrom = <function 12>,
  removeserver = <function 13>,
  removethread = <function 14>,
  running = false,
  send = <function 15>,
  sendto = <function 16>,
  setErrorHandler = <function 17>,
  settimeout = <function 18>,
  sleep = <function 19>,
  step = <function 20>,
  timeout = <function 21>,
  useSocketTimeoutErrors = <function 22>,
  wakeup = <function 23>,
  wrap = <function 24>
}
]]

--- @meta
--- @module 'libs/copas/copas'

--- @class copas
--- @field _COPYRIGHT string
--- @field _DESCRIPTION string
--- @field _VERSION string
--- @field autoclose boolean
--- @field running boolean
local copas = {}

--- Adds a new server to the list of servers to be handled by copas.
--- @param server table
--- @param handler function
--- @param timeout number
--- @return nil
function copas.addserver(server, handler, timeout) end

--- Adds a new thread to the list of threads to be handled by copas.
--- @param thread thread
--- @vararg any
--- @return thread thread
function copas.addthread(thread, ...) end

--- Connects to a server.
--- @param socket table
--- @param host string
--- @param port number
--- @return boolean success, string error
function copas.connect(socket, host, port) end
