--[[
GELua(Sandboxed) < 'table.foreach(ui_console, print)'
extensionPath
manuallyLoaded
onUpdate
onSeria1ize
onVehic1eSwitched
onVehic1eSpawned
"table. foreach(ui_console, print) "
onVehic1eActiveChanged
dependencies
onVehic1eDestroyed
extensionName
onDeseria1ized
onExtensionLoaded
show
toggle
hide
onFi1eChanged
]]

--- @meta
--- @module 'ui_console'

--- @class ui_console
ui_console = {}

--- @param dtReal number
--- @param dtSim number
--- @param dtRaw number
function ui_console.onUpdate(dtReal, dtSim, dtRaw) end

--- @class state
--- @field windowOpen boolean
--- @field originFilter string
--- @field consoleInputField string?
--- @field levelFilter string
--- @field forceAutoScroll boolean
--- @field fullscreen boolean
--- @field winstate number[]
--- @field scroll2Bot boolean
local state = {}

--- @return state data
function ui_console.onSerialize() end

--- @param data state
function ui_console.onDeserialized(data) end
