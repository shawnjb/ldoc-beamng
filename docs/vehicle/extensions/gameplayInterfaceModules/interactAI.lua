-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}

local moduleName = "interactAI"
M.moduleActions = {}
M.moduleLookups = {}

local function setAIMode(params)
  local dataTypeCheck, dataTypeError = checkTableDataTypes(params, { "string" })
  if not dataTypeCheck then
    return { failReason = dataTypeError }
  end
  local mode = params[1]
  ai.setMode(mode)
end

local function requestRegistration(gi)
  gi.registerModule(moduleName, M.moduleActions, M.moduleLookups)
end

local function onExtensionLoaded()
  M.moduleActions.setAIMode = setAIMode
end

M.onExtensionLoaded = onExtensionLoaded
M.requestRegistration = requestRegistration

return M
