--- @meta

--- @class obj
--- @field position vec3
local obj = {}

--- Returns whether or not the World Editor can select this object.
--- @param self obj The object to check.
--- @return boolean enabled Whether selection is enabled.
function obj:isSelectionEnabled() end

--- Returns whether or not Torque3D can render this object.
--- @param self obj The object to check.
--- @return boolean enabled Whether rendering is enabled.
function obj:isRenderEnabled() end

--- Returns whether or not the object is hidden.
--- @param self obj The object to check.
--- @return boolean hidden Whether the object is hidden.
function obj:isHidden() end

--- Returns whether or not the object is locked.
--- @param self obj The object to check.
--- @return boolean locked Whether the object is locked.
function obj:isLocked() end

--- @class obj.vehicle:obj
--- @field position vec3
--- @field color vec3
--- @field renderFade number
--- @field jbeam string
--- @field metallicPaintData vec3
--- @field partConfig string
local vehicle = {}

--- Returns the number of nodes in the selection.
--- @param self obj.vehicle The object to get the number of nodes from.
--- @return number nodes The number of nodes in the selection.
function vehicle:getNodeCount() end

--- Returns the number of beams in the selection.
--- @param self obj.vehicle The object to get the number of beams from.
--- @return number beams The number of beams in the selection.
function vehicle:getBeamCount() end

--- Returns the bounding box of the vehicle.
--- @param self obj.vehicle The object to get the bounding box from.
--- @return obj.boundingbox boundingbox The bounding box of the vehicle.
function vehicle:getSpawnWorldOOBB() end

--- @class obj.boundingbox:obj
local boundingbox = {}

--- Returns the half extents of the bounding box.
--- @param self obj.boundingbox The bounding box to get the half extents from.
--- @return vec3 halfExtents The half extents of the bounding box.
function boundingbox:getHalfExtents() end

--- Returns the center of the bounding box.
--- @param self obj.boundingbox The bounding box to get the center from.
--- @return vec3 center The center of the bounding box.
function boundingbox:getCenter() end
