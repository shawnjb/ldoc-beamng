--[[
<1>{ <2>{
    ___type = "static_class<SimObjectMemento>",
    __call = <function 1>,
    __index = <function 2>
  },
  ___type = "static_class<SimObjectMemento>",
  __call = <function 1>,
  __index = <table 2>,
  <metatable> = <table 1>
}
]]

--- @meta

--- @class SimObjectMemento: userdata
--- @field ___type 'static_class<SimObjectMemento>'
local SimObjectMemento = {}

--- Call this table as a function to create a new SimObjectMemento object.
--- @return SimObjectMemento
function SimObjectMemento:__call() end

--- Returns the index of the given SimObjectMemento object.
--- @param self SimObjectMemento
--- @param index string
--- @return any
function SimObjectMemento:__index(index) end

--- Sets the index of the given SimObjectMemento object.
--- @param self SimObjectMemento
--- @param index string
--- @param value any
function SimObjectMemento:__newindex(index, value) end
