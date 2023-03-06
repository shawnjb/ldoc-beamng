-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local im  = ui_imgui
local C = {}
local level = {'check','warning','error'}
local icons  = {'check','warning','error'}
local infoColors = {
  warning = im.ImVec4(1, 1, 0, 1.0),
  error = im.ImVec4(1, 0, 0, 1.0)
}

function C:init(missionEditor)
  self.missionEditor = missionEditor
  self.issues = {list = {}}
end

function C:setMission(mission)
  self.mission = mission
end

function C:draw()
  if not self.mission._issueList then return end
  im.Columns(2)
  im.SetColumnWidth(0,150)

  im.Text("Issues")
  im.NextColumn()
  if self.mission._issueList.count == 0 then
    im.Text("No Issues!")
  end

  for _, issue in ipairs(self.mission._issueList) do
    im.BulletText(issue.label)
  end
  im.Columns(1)

end

local severityPriority = {unknown = -1, minor=1, warning = 10, error = 50, critical = 100}

local function sortByIdx(a,b) return a.idx < b.idx end
local function sortBySeverity(a,b)
  if severityPriority[a.severity] == severityPriority[b.severity] then
    return sortByIdx(a,b)
  else
    return severityPriority[a.severity] < severityPriority[b.severity]
  end
end
local function sortByMission(a,b)
  if a.missionId == b.missionId then
    return sortByIdx(a,b)
  else
    return a.missionId < b.missionId
  end
end
local function sortByLabel(a,b)
  if a.label == b.label then
    return sortByIdx(a,b)
  else
    return a.label < b.label
  end
end

function getSortingFunction(columnIdx)
  if columnIdx == 0 then return sortByIdx end
  if columnIdx == 1 then return sortBySeverity end
  if columnIdx == 2 then return sortByMission end
  if columnIdx == 3 then return sortByLabel end
  return sortByIdx
end

function C:drawIssuesWindow()
  if editor.beginWindow('mission_issues', "Mission Issues Overview",  im.WindowFlags_MenuBar) then
    if im.BeginTable('', 4, bit.bor(im.TableFlags_Sortable)) then
      im.TableSetupColumn("#",nil,5)
      im.TableSetupColumn("",nil,5) -- severity
      im.TableSetupColumn("Mission",nil,20)
      im.TableSetupColumn("Label", nil,60)
      im.TableHeadersRow()
      im.TableNextColumn()
      if im.TableGetSortSpecs().SpecsDirty then

        table.sort(self.issues.list, getSortingFunction(im.TableGetSortSpecs().Specs.ColumnIndex))
        if im.TableGetSortSpecs().Specs.SortDirection == 1 then
          arrayReverse(self.issues.list)
        end
        im.TableGetSortSpecs().SpecsDirty = false
      end

      for _, issue in ipairs(self.issues.list or {}) do
        im.Text(issue.idx.."")
        im.TableNextColumn()
        im.Text(issue.severity)
        im.TableNextColumn()
        local name = issue.missionId
        if editor.getPreference('missionEditor.general.shortIds') then
          local p, fn, _ = path.split(name)
          name = fn
        end
        im.Text(name)
        im.TableNextColumn()
        im.Text(issue.label)
        im.TableNextColumn()
      end
      im.EndTable()
    end

    editor.endWindow()
  end
end

function C:showIssuesWindow()
  editor.showWindow('mission_issues')
end



function C:calculateMissionIssues(missionList, windows, missionTypeWindow)
  self.issues = {list = {}}
  local idx = 1
  for _, mission in ipairs(missionList) do

    missionTypeWindow:setMission(mission)
    mission._issueList = {list = {}, count = 0, highestSeverity = 'unknown'}
    for _, w in ipairs(windows) do
      if w.getMissionIssues then
        for _, issue in ipairs(w:getMissionIssues(mission) or {}) do

          issue.label = issue.label or "Unknown Issue"
          issue.severity = issue.severity or "unknown"
          issue.idx = idx
          idx = idx+1

          issue.missionId = mission.id
          table.insert(self.issues.list, issue)
          table.insert(mission._issueList, issue)
          mission._issueList.count = mission._issueList.count + 1
          if severityPriority[mission._issueList.highestSeverity] < severityPriority[issue.severity] then
            mission._issueList.highestSeverity = issue.severity
          end
        end
      end
      if mission._issueList.count == 0 then
        mission._issueList.icon = 'check'
        mission._issueList.color = im.ImVec4(0, 1, 0, 1.0)
      else
        local c = math.min(mission._issueList.count, 10)
        mission._issueList.color = im.ImVec4(0.8+c*0.02, 0.8-0.08*c, 0, 1.0)
        mission._issueList.icon = 'warning'
      end
    end
  end
end

return function(...)
  local o = {}
  setmetatable(o, C)
  C.__index = C
  o:init(...)
  return o
end
