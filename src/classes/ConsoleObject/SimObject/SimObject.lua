--[=[
<1>{ {
    className = <function 1>
  }, {}, <2>{ <3>{
      ___type = "class<ConsoleObject>",
      __gc = <function 2>,
      __index = <function 3>,
      getFieldInfo = <function 4>,
      getFieldList = <function 5>,
      getFields = <function 6>,
      getFieldsForEditor = <function 7>
    },
    ___type = "class<ConsoleObject>",
    __gc = <function 2>,
    __index = <table 3>,
    <metatable> = <table 2>
  }, <function 8>, <function 9>, <function 10>, <function 11>,
  ___type = "class<SimObject>",
  __gc = <function 12>,
  __index = <function 13>,
  __newindex = <function 14>,
  __tostring = <function 15>,
  assignFieldsFromObject = <function 16>,
  clone = <function 17>,
  decRefCount = <function 18>,
  delete = <function 19>,
  deleteObject = <function 20>,
  deletePersistentId = <function 21>,
  dump = <function 22>,
  dumpGroupHierarchy = <function 23>,
  generatePersistentId = <function 24>,
  getClassName = <function 1>,
  getDeclarationLine = <function 25>,
  getDynDataFieldbyName = <function 9>,
  getDynamicFields = <function 26>,
  getField = <function 27>,
  getFieldInfo = <function 4>,
  getFieldList = <function 5>,
  getFields = <function 6>,
  getFieldsForEditor = <function 7>,
  getFileName = <function 28>,
  getGroup = <function 29>,
  getID = <function 30>,
  getId = <function 31>,
  getInternalName = <function 32>,
  getName = <function 33>,
  getOrCreatePersistentID = <function 34>,
  getStaticDataFieldbyIndex = <function 35>,
  getStaticDataFieldbyName = <function 8>,
  incRefCount = <function 36>,
  inheritParentFields = <function 37>,
  inspectUpdate = <function 38>,
  isChildOfGroup = <function 39>,
  isEditorDirty = <function 40>,
  isHidden = <function 41>,
  isLocked = <function 42>,
  isNameChangeAllowed = <function 43>,
  isSelected = <function 44>,
  isSubClassOf = <function 45>,
  onEditorDisable = <function 46>,
  onEditorEnable = <function 47>,
  postApply = <function 48>,
  preApply = <function 49>,
  registerObject = <function 50>,
  save = <function 51>,
  serialize = <function 52>,
  serializeForEditor = <function 53>,
  serializeToDirectories = <function 54>,
  serializeToNameDictFile = <function 55>,
  setCanSave = <function 56>,
  setDeclarationLine = <function 57>,
  setDynDataFieldbyName = <function 11>,
  setEditorDirty = <function 58>,
  setEditorOnly = <function 59>,
  setField = <function 60>,
  setFileName = <function 61>,
  setHidden = <function 62>,
  setInternalName = <function 63>,
  setIsSelected = <function 64>,
  setLocked = <function 65>,
  setName = <function 66>,
  setNameChangeAllowed = <function 67>,
  setSelected = <function 68>,
  setStaticDataFieldbyIndex = <function 69>,
  setStaticDataFieldbyName = <function 10>,
  unregisterObject = <function 70>,
  <metatable> = <table 1>
}
]=]

--- @meta

--- @class SimObject: ConsoleObject
--- @field ___type 'class<SimObject>'
local SimObject = {}

function SimObject:__gc() end
function SimObject:__index(self, index) end
function SimObject:__newindex(self, index, value) end
function SimObject:__tostring() end
function SimObject:assignFieldsFromObject(fromObject) end
function SimObject:clone() end
function SimObject:decRefCount() end
function SimObject:delete() end
function SimObject:deleteObject() end
function SimObject:deletePersistentId() end
function SimObject:dump() end
function SimObject:dumpGroupHierarchy() end

--- Sets the object's persistent ID.
--- @param objectId number
function SimObject:setForcedId(objectId) end

function SimObject:generatePersistentId() end
function SimObject:getClassName() end
function SimObject:getDeclarationLine() end
function SimObject:getDynDataFieldbyName(name) end
function SimObject:getDynamicFields() end
function SimObject:getField(name) end
function SimObject:getFieldInfo(name) end
function SimObject:getFieldList() end
function SimObject:getFields() end
function SimObject:getFieldsForEditor() end
function SimObject:getFileName() end
function SimObject:getGroup() end

--- Returns the object's ID.
--- @return number objectId
function SimObject:getID() end

--- Returns the object's ID.
--- @return number objectId
function SimObject:getId() end

--- Returns the object's internal name.
--- @return string internalName
function SimObject:getInternalName() end

--- Returns the object's name.
--- @return string name
function SimObject:getName() end

--- Returns the object's persistent ID.
--- @return number objectId
function SimObject:getOrCreatePersistentID() end

--- Returns the object's static data field by index.
--- @param index number
--- @return string value
function SimObject:getStaticDataFieldbyIndex(index) end

--- Returns the object's static data field by name.
--- @param name string
--- @return string value
function SimObject:getStaticDataFieldbyName(name) end
function SimObject:incRefCount() end
function SimObject:inheritParentFields() end
function SimObject:inspectUpdate() end

--- Returns whether the object is a child of the given group.
--- @param group SimGroup
function SimObject:isChildOfGroup(group) end

--- Returns whether the object is dirty in the World Editor.
--- @return boolean dirty
function SimObject:isEditorDirty() end

--- Returns whether the object is hidden.
--- @return boolean hidden
function SimObject:isHidden() end

--- Returns whether the object is locked.
--- @return boolean locked
function SimObject:isLocked() end

--- Returns whether the object's name can be changed.
--- @return boolean nameChangeAllowed
function SimObject:isNameChangeAllowed() end

--- Returns whether the object is selected.
--- @return boolean selected
function SimObject:isSelected() end

--- Returns whether the object is a subclass of the given class name.
--- @param className string
--- @return boolean isSubClass
function SimObject:isSubClassOf(className) end

--- Called when the object is disabled from the World Editor.
function SimObject:onEditorDisable() end

--- Called when the object is enabled from the World Editor.
function SimObject:onEditorEnable() end

--- Called after changes to the object are applied.
function SimObject:postApply() end

--- Called before changes to the object are applied.
function SimObject:preApply() end

--- Registers the object with the engine.
--- @param name string
function SimObject:registerObject(name) end

--- Saves the object to a file.
--- @param fileName string
--- @param selectedOnly boolean
--- @param preAppendString? string
function SimObject:save(fileName, selectedOnly, preAppendString) end

function SimObject:serialize() end
function SimObject:serializeForEditor() end
function SimObject:serializeToDirectories() end
function SimObject:serializeToNameDictFile() end

--- Set whether the object will be included in saves.
--- @param value boolean
function SimObject:setCanSave(value) end

--- Returns the line number at which the object is defined in it's file.
--- @return integer line
function SimObject:setDeclarationLine(line) end

function SimObject:setDynDataFieldbyName(name, value) end
function SimObject:setEditorDirty(dirty) end
function SimObject:setEditorOnly(editorOnly) end
function SimObject:setField(name, value) end
function SimObject:setFileName(fileName) end
function SimObject:setHidden(hidden) end
function SimObject:setInternalName(internalName) end
function SimObject:setIsSelected(selected) end

--- Sets whether the object is locked.
--- @param locked boolean
function SimObject:setLocked(locked) end

--- Sets the object's name.
--- @param name string
function SimObject:setName(name) end

--- Sets whether the object's name can be changed.
--- @param allowed boolean
function SimObject:setNameChangeAllowed(allowed) end
function SimObject:setSelected(selected) end
function SimObject:setStaticDataFieldbyIndex(index, value) end
function SimObject:setStaticDataFieldbyName(name, value) end
function SimObject:unregisterObject() end

return SimObject
