--- @meta
--- @module 'matrix'

--- @class matrix
matrix = {}

--- @alias column
--- | 1 # The forward vector.
--- | 2 # The left vector.
--- | 3 # The up vector.
--- | 4 # The position vector.

--- Returns a column of the matrix.
--- @param column column
--- @return vec3
function matrix:getColumn(column) end

return matrix
