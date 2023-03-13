--[[
{
  __extensionName__ = "gameplay_missions_missions",
  __extensionPath__ = "gameplay/missions/missions",
  __manuallyLoaded__ = true,
  baseMission = <function 1>,
  clearCache = <function 2>,
  createMission = <function 3>,
  dependencies = { "gameplay_missions_missionManager", "gameplay_missions_startTrigger", "freeroam_bigMapMode", "gameplay_missions_progress" },
  editorHelper = <function 4>,
  flowMission = <function 5>,
  get = <function 6>,
  getAdditionalAttributes = <function 7>,
  getAllIds = <function 8>,
  getFilesData = <function 9>,
  getLocations = <function 10>,
  getMissionById = <function 11>,
  getMissionConstructor = <function 12>,
  getMissionEditorForType = <function 13>,
  getMissionPreviewFilepath = <function 14>,
  getMissionProgressSetupData = <function 15>,
  getMissionStaticData = <function 16>,
  getMissionTypes = <function 17>,
  getMissionsByMissionType = <function 18>,
  getNoPreviewFilepath = <function 19>,
  getNoThumbFilepath = <function 20>,
  getRecommendedAttributesList = <function 21>,
  loadMission = <function 22>,
  onExtensionLoaded = <function 23>,
  recursiveRemoveNestedFromCondition = <function 24>,
  reloadCompleteMissionSystem = <function 25>,
  sanitizeMissionAfterCreation = <function 26>,
  saveMission = <function 27>
}
]]

--- @meta
--- @module 'gameplay_missions_missions'

--- @class gameplay_missions_missions
--- @field __extensionName__ string
--- @field __extensionPath__ string
--- @field __manuallyLoaded__ boolean
--- @field baseMission function
--- @field clearCache function
--- @field createMission function
--- @field dependencies table
--- @field editorHelper function
--- @field flowMission function
--- @field get function
--- @field getAdditionalAttributes function
--- @field getAllIds function
--- @field getFilesData function
--- @field getLocations function
--- @field getMissionById function
--- @field getMissionConstructor function
--- @field getMissionEditorForType function
--- @field getMissionPreviewFilepath function
--- @field getMissionProgressSetupData function
--- @field getMissionStaticData function
--- @field getMissionTypes function
--- @field getMissionsByMissionType function
--- @field getNoPreviewFilepath function
--- @field getNoThumbFilepath function
--- @field getRecommendedAttributesList function
--- @field loadMission function
--- @field onExtensionLoaded function
--- @field recursiveRemoveNestedFromCondition function
--- @field reloadCompleteMissionSystem function
--- @field sanitizeMissionAfterCreation function
--- @field saveMission function
gameplay_missions_missions = {}
