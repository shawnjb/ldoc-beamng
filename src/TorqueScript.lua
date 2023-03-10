--- @meta
--- @module 'TorqueScript'

--- @class TorqueScript
TorqueScript = {}

--- Evaluates a string of TorqueScript code.
--- @param code string The code to evaluate.
--- @return any
function TorqueScript:eval(code) end

--- Executes a file of TorqueScript code.
--- @param path string The path to the file to execute.
--- @return any
function TorqueScript:exec(path) end

--- Returns the value of a console variable.
--- @param name string The name of the console variable.
--- @return any
function getConsoleVariable(name) end

--- Applies a value to a console variable.
--- @param name string The name of the console variable.
--- @param value any The value to apply.
function setConsoleVariable(name, value) end
