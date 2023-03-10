--- @meta
--- @module 'M'

--- @class Extension
--- @field openWindow (fun(): any)? What happens when the window is opened.
--- @field closeWindow  (fun(): any)? What happens when the window is closed.
--- @field onEditorInitialized  (fun(): any)? Called when the editor is initialized.
--- @field onExtensionLoaded (fun(): any)? Called when the extension is loaded.
--- @field onPreRender (fun(dtReal: number, dtSim: number, dtRaw: number): any)? Called before each frame is rendered.
M = {}
