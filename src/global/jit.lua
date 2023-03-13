--- @meta
--- @module 'jit'

--- @class jit
--- @field arch string
--- @field os string
--- @field version string
--- @field version_num number
--- @version LuaJIT
jit = {}

--- Attaches a profiler to the given function.
--- @param func function
--- @param name string
--- @return function
function jit.attach(func, name) end

--- Flushes the profiler output.
function jit.flush() end

--- Turns off the profiler.
function jit.off() end

--- Turns on the profiler.
function jit.on() end

--- @class jit.opt
--- @field start function
jit.opt = {}

--- Starts the profiler.
--- @vararg any
function jit.opt.start(...) end

--- Sets the security level.
--- @param level number
function jit.security(level) end

--- Returns the profiler status.
--- @return string
function jit.status() end
