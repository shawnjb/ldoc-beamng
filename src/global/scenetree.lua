--[[
{
  <metatable> = {
    __index = <function 1>,
    __newindex = <function 2>,
    findClassObjects = <function 3>,
    findObject = <function 4>,
    findObjectById = <function 5>,
    getAllObjects = <function 6>,
    objectExists = <function 7>,
    objectExistsById = <function 8>
  }
}
]]

--- @meta

--- The `scenetree` variable provides functions for interacting with the scenetree. It is a singleton object that is available globally.
--- @class scenetree: table
scenetree = {}

--- Returns the index of the given scenetree object.
--- @param self scenetree
--- @param index string
--- @return any
function scenetree:__index(index) end

--- Sets the index of the given scenetree object.
--- @param self scenetree
--- @param index string
--- @param value any
function scenetree:__newindex(index, value) end

--- Returns a list of objects with the given class name.
--- @param className string
--- @return table
function scenetree.findClassObjects(className) end

--- Finds an object by name.
--- @param name string
--- @return SimObject
function scenetree.findObject(name) end

--- Finds an object by ID.
--- @param id number
--- @return SimObject
function scenetree.findObjectById(id) end

--- Returns a list of all objects.
--- @return table
function scenetree.getAllObjects() end

--- Returns whether an object exists.
--- @param name string
--- @return boolean
function scenetree.objectExists(name) end

--- Returns whether an object exists.
--- @param id number
--- @return boolean
function scenetree.objectExistsById(id) end
