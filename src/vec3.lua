--- @meta

--- Creates a new 3D vector.
--- @param x number
--- @param y number
--- @param z number
--- @return vec3
function vec3(x, y, z) end

--- Internally used. Creates a new 3D vector.
--- @param x number
--- @param y number
--- @param z number
--- @return vec3
function Vector3(x, y, z) end

--- 3D vector with X, Y & Z components.
--- @class vec3
--- @version <5.2,LuaJIT
local vec3 = {}

--- Applies a new X, Y & Z component to the vector.
--- @param self vec3
--- @param x number
--- @param y number
--- @param z number
function vec3:set(self, x, y, z) end

--- Returns the X, Y & Z components of the vector.
--- @param self vec3
--- @return number x
--- @return number y
--- @return number z
function vec3:get(self) end

--- Creates a new 3D vector from a string.
--- @param str string
--- @return vec3
function vec3:fromString(str) end

--- Creates a new table from the vector.
--- @param self vec3
--- @return table | { [number]: number }
function vec3:toTable(self) end

--- Creates a new 3D vector from a table.
--- @param t table | { [number]: number }
function vec3:setFromTable(t) end

--- Converts the vector to an array.
--- @param self vec3
--- @return { x: number, y: number, z: number }
function vec3:toDict(self) end

--- Returns the length of the vector.
--- @param self vec3
--- @return number
function vec3:length(self) end

--- Adds two vectors.
--- @param self vec3
--- @param other vec3
--- @return vec3
function vec3.__add(self, other) end

--- Subtracts two vectors.
--- @param self vec3
--- @param other vec3
--- @return vec3
function vec3.__sub(self, other) end

--- Multiplies two vectors.
--- @param self vec3
--- @param other vec3
--- @return vec3
function vec3.__mul(self, other) end

--- Divides two vectors.
--- @param self vec3
--- @param other vec3
--- @return vec3
function vec3.__div(self, other) end

--- Negates a vector.
--- @param self vec3
--- @return vec3
function vec3.__unm(self) end

--- Compares two vectors.
--- @param self vec3
--- @param other vec3
--- @return boolean
function vec3.__eq(self, other) end

--- Returns a string representation of the vector.
--- @param self vec3
--- @return string
function vec3.__tostring(self) end

return vec3
