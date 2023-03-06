-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxiliary"

local couplerStates = {
  attached = "attached",
  coupling = "coupling",
  autoCoupling = "autoCoupling",
  detached = "detached",
  broken = "broken",
  desyncedAttached = "desyncedAttached",
  desyncedDetached = "desyncedDetached"
}

local couplerGroupTypes = {
  default = "default",
  autoCoupling = "autoCoupling",
  manualClose = "manualClose"
}

local detachSoundStateLookup = {
  [couplerStates.attached] = true,
  [couplerStates.desyncedAttached] = true
}

local attachSoundStateLookup = {
  [couplerStates.detached] = true,
  [couplerStates.coupling] = true,
  [couplerStates.autoCoupling] = true,
  [couplerStates.desyncedAttached] = true
}

local toggleDetachStateLookup = {
  [couplerStates.attached] = true,
  [couplerStates.detached] = true,
  [couplerStates.coupling] = true,
  [couplerStates.autoCoupling] = true,
  [couplerStates.desyncedAttached] = true
}

local toggleAttachStateLookup = {
  [couplerStates.detached] = true,
  [couplerStates.coupling] = true,
  [couplerStates.autoCoupling] = true,
  [couplerStates.broken] = true,
  [couplerStates.desyncedDetached] = true
}

local couplerGroup
local autoLatchesToActivate

local function tryAttachGroupImpulse()
  if couplerGroup.groupType == couplerGroupTypes.manualClose then
    for _, cnp in ipairs(couplerGroup.couplerNodePairs) do
      if cnp.state == couplerStates.detached then
        --obj:attachLocalCoupler(nid1, nid2, strength, radius, lockRadius, latchSpeed, bool persistLatch)
        obj:attachLocalCoupler(cnp.cid1, cnp.cid2, cnp.autoCouplingStrength, cnp.autoCouplingRadius, cnp.autoCouplingLockRadius, cnp.autoCouplingSpeed, true)
        cnp.state = couplerStates.autoCoupling
      end
    end
  end
  couplerGroup.closeForceTimer = couplerGroup.closeForceDuration
end

local function detachGroup()
  for _, cnp in ipairs(couplerGroup.couplerNodePairs) do
    obj:detachCoupler(cnp.cid1, 0)
  end

  couplerGroup.openForceTimer = couplerGroup.openForceDuration
end

local function toggleGroup()
  if couplerGroup.openForceTimer > 0 or couplerGroup.closeForceTimer > 0 then
    return
  end
  if toggleAttachStateLookup[couplerGroup.groupState] then
    tryAttachGroupImpulse()
  elseif toggleDetachStateLookup[couplerGroup.groupState] then
    detachGroup()
  end
end

local function toggleGroupConditional(conditions)
  for _, c in ipairs(conditions) do
    if #c < 2 then
      log("E", "advancedCouplerControl.toggleGroupConditional", "Wrong amount of data for condition, expected 2:")
      log("E", "advancedCouplerControl.toggleGroupConditional", dumps(c))
      return
    end
    local controllerName = c[1]
    local nonAllowedState = c[2]
    local errorMessage = c[3]
    if not controllerName or not nonAllowedState then
      log("E", "advancedCouplerControl.toggleGroupConditional", string.format("Wrong condition data, groupName: %q, nonAllowedState: %q", controllerName, nonAllowedState))
      return
    end
    local groupController = controller.getController(controllerName)
    if not groupController or groupController.typeName ~= "advancedCouplerControl" then
      log("E", "advancedCouplerControl.toggleGroupConditional", string.format("Can't find group controller with name %q or it's the wrong type", controllerName))
      return
    end
    local groupState = groupController.getGroupState()
    if groupState == nonAllowedState then
      -- group is in wrong state, don't continue
      guihooks.message(errorMessage, 5, "vehicle.advancedCouplerControl." .. controllerName .. nonAllowedState .. errorMessage)
      return
    end
  end
  toggleGroup()
end

local function syncGroupState()
  local currentStates = {}
  for _, coupler in ipairs(couplerGroup.couplerNodePairs) do
    currentStates[coupler.state] = true
  end

  local groupState
  if tableSize(currentStates) == 1 then
    groupState = couplerGroup.couplerNodePairs[1].state
  else
    if currentStates[couplerStates.attached] then
      groupState = couplerStates.desyncedAttached
    else
      groupState = couplerStates.desyncedDetached
    end
  end
  couplerGroup.groupState = groupState
  local notAttachedElectricsName = M.name .. "_notAttached"
  electrics.values[notAttachedElectricsName] = groupState == couplerStates.attached and 0 or 1
end

local function updateGFX(dt)
  if couplerGroup.spawnSoundDelayTimer > 0 then
    couplerGroup.spawnSoundDelayTimer = couplerGroup.spawnSoundDelayTimer - dt
    if couplerGroup.spawnSoundDelayTimer <= 0 then
      couplerGroup.canPlaySounds = true
    end
  end

  if #autoLatchesToActivate > 0 then
    local activatedAutoLatches = {}
    for key, couplerIndex in ipairs(autoLatchesToActivate) do
      local cnp = couplerGroup.couplerNodePairs[couplerIndex]
      local nodeDistance = obj:nodeLength(cnp.cid1, cnp.cid2)
      if nodeDistance > cnp.autoCouplingRadius * 2 then
        table.insert(activatedAutoLatches, key)
        if cnp.state == couplerStates.detached then
          --obj:attachLocalCoupler(nid1, nid2, strength, radius, lockRadius, latchSpeed, bool persistLatch)
          obj:attachLocalCoupler(cnp.cid1, cnp.cid2, cnp.autoCouplingStrength, cnp.autoCouplingRadius, cnp.autoCouplingLockRadius, cnp.autoCouplingSpeed, true)
          cnp.state = couplerStates.autoCoupling
        end
      end
    end

    for _, key in ipairs(activatedAutoLatches) do
      table.remove(autoLatchesToActivate, key)
    end

    syncGroupState()
  end

  if couplerGroup.openForceTimer > 0 then
    couplerGroup.openForceTimer = couplerGroup.openForceTimer - dt
    for _, cnp in ipairs(couplerGroup.couplerNodePairs) do
      obj:applyForceTime(cnp.applyForceCid2, cnp.applyForceCid1, -couplerGroup.openForceMagnitude * couplerGroup.invCouplerNodePairCount, dt)
    end
  end

  if couplerGroup.closeForceTimer > 0 then
    couplerGroup.closeForceTimer = couplerGroup.closeForceTimer - dt
    for _, cnp in ipairs(couplerGroup.couplerNodePairs) do
      obj:applyForceTime(cnp.applyForceCid2, cnp.applyForceCid1, couplerGroup.closeForceMagnitude * couplerGroup.invCouplerNodePairCount, dt)
    end
  end
end

local function onCouplerFound(nodeId, obj2id, obj2nodeId)
  --dump(couplerGroup)
end

local function onCouplerAttached(nodeId, obj2id, obj2nodeId, attachSpeed)
  local couplerIndex = couplerGroup.couplerNodeIdLookup[nodeId]
  if couplerIndex then
    couplerGroup.couplerNodePairs[couplerIndex].state = couplerStates.attached

    local isCorrectPastState = attachSoundStateLookup[couplerGroup.groupState]
    syncGroupState()
    local isCorrectCurrentState = couplerGroup.groupState == couplerStates.attached
    if isCorrectPastState and isCorrectCurrentState and couplerGroup.canPlaySounds then
      local aggressionCoef = linearScale(attachSpeed, 0.1, 1, 0, 1)
      obj:playSFXOnceCT(couplerGroup.attachSoundEvent, couplerGroup.soundNode, couplerGroup.attachSoundVolume, 0.5, aggressionCoef, 0)
    end

    if couplerGroup.groupState == couplerStates.attached then
      couplerGroup.closeForceTimer = 0
      couplerGroup.openForceTimer = 0
    end
  end
end

local function onCouplerDetached(nodeId, obj2id, obj2nodeId, breakForce)
  local couplerIndex = couplerGroup.couplerNodeIdLookup[nodeId]
  if couplerIndex then
    couplerGroup.couplerNodePairs[couplerIndex].state = breakForce <= 0 and couplerStates.detached or couplerStates.broken
    if couplerGroup.couplerNodePairs[couplerIndex].state == couplerStates.detached and couplerGroup.groupType == couplerGroupTypes.autoCoupling then
      table.insert(autoLatchesToActivate, couplerIndex)
    end
    local isCorrectPastState = detachSoundStateLookup[couplerGroup.groupState]
    syncGroupState()
    local isCorrectCurrentState = couplerGroup.groupState == couplerStates.detached
    if isCorrectPastState and isCorrectCurrentState then
      obj:playSFXOnceCT(couplerGroup.detachSoundEvent, couplerGroup.soundNode, couplerGroup.detachSoundVolume, 0.5, 1, 0)
    end
  end
end

local function onGameplayEvent(eventName, ...)
end

local function getGroupState()
  return couplerGroup.groupState
end

local function resetSounds(jbeamData)
end

local function reset(jbeamData)
  autoLatchesToActivate = {}
  couplerGroup.canPlaySounds = false
  couplerGroup.spawnSoundDelayTimer = 0.1
  couplerGroup.closeForceTimer = 0
  couplerGroup.openForceTimer = 0
  couplerGroup.groupState = couplerStates.detached
  for _, cnp in ipairs(couplerGroup.couplerNodePairs) do
    cnp.state = couplerStates.detached
    if cnp.couplingStartRadius then
      obj:attachLocalCoupler(cnp.cid1, cnp.cid2, cnp.autoCouplingStrength, cnp.couplingStartRadius, cnp.autoCouplingLockRadius, cnp.autoCouplingSpeed, true)
    end
  end
end

local function initSounds(jbeamData)
end

local function init(jbeamData)
  --print(M.name)
  --dump(jbeamData)

  couplerGroup = {
    couplerNodeIdLookup = {},
    couplerNodePairs = {},
    groupState = couplerStates.detached,
    soundNode = jbeamData.soundNode_nodes and jbeamData.soundNode_nodes[1] or 0,
    attachSoundEvent = jbeamData.attachSoundEvent,
    detachSoundEvent = jbeamData.detachSoundEvent,
    breakSoundEvent = jbeamData.breakSoundEvent,
    attachSoundVolume = jbeamData.attachSoundVolume,
    detachSoundVolume = jbeamData.detachSoundVolume,
    breakSoundVolume = jbeamData.breakSoundVolume,
    canPlaySounds = false,
    spawnSoundDelayTimer = 0.1,
    groupType = jbeamData.groupType or couplerGroupTypes.default,
    openForceMagnitude = jbeamData.openForceMagnitude or 100,
    openForceDuration = jbeamData.openForceDuration or 0.2,
    closeForceMagnitude = jbeamData.closeForceMagnitude or 100,
    closeForceDuration = jbeamData.closeForceDuration or 0.3,
    closeForceTimer = 0,
    openForceTimer = 0
  }

  local nodeData = tableFromHeaderTable(jbeamData.couplerNodes)

  for _, cnp in ipairs(nodeData) do
    local couplerNodePairData = {
      cid1 = beamstate.nodeNameMap[cnp.cid1],
      cid2 = beamstate.nodeNameMap[cnp.cid2],
      applyForceCid1 = beamstate.nodeNameMap[cnp.forceCid1 or cnp.cid1],
      applyForceCid2 = beamstate.nodeNameMap[cnp.forceCid2 or cnp.cid2],
      autoCouplingStrength = cnp.autoCouplingStrength or 40000,
      autoCouplingRadius = cnp.autoCouplingRadius or 0.01,
      autoCouplingLockRadius = cnp.autoCouplingLockRadius or 0.005,
      autoCouplingSpeed = cnp.autoCouplingSpeed or 0.2,
      couplingStartRadius = cnp.couplingStartRadius,
      breakGroup = cnp.breakGroup,
      state = couplerStates.detached
    }
    table.insert(couplerGroup.couplerNodePairs, couplerNodePairData)
    couplerGroup.couplerNodeIdLookup[couplerNodePairData.cid1] = #couplerGroup.couplerNodePairs
    couplerGroup.couplerNodeIdLookup[couplerNodePairData.cid2] = couplerGroup.couplerNodeIdLookup[couplerNodePairData.cid1]
    if couplerNodePairData.couplingStartRadius then
      obj:attachLocalCoupler(couplerNodePairData.cid1, couplerNodePairData.cid2, couplerNodePairData.autoCouplingStrength, couplerNodePairData.couplingStartRadius, couplerNodePairData.autoCouplingLockRadius, couplerNodePairData.autoCouplingSpeed, true)
    end
    if couplerNodePairData.breakGroup then
      beamstate.registerExternalCouplerBreakGroup(couplerNodePairData.breakGroup, couplerNodePairData.cid1)
    end
  end
  couplerGroup.invCouplerNodePairCount = 1 / #couplerGroup.couplerNodePairs

  autoLatchesToActivate = {}
  syncGroupState()
end

M.init = init
M.initSounds = initSounds

M.reset = reset
M.resetSounds = resetSounds

M.updateGFX = updateGFX

M.onCouplerFound = onCouplerFound
M.onCouplerAttached = onCouplerAttached
M.onCouplerDetached = onCouplerDetached

M.onGameplayEvent = onGameplayEvent

M.toggleGroup = toggleGroup
M.toggleGroupConditional = toggleGroupConditional
M.tryAttachGroupImpulse = tryAttachGroupImpulse
M.detachGroup = detachGroup
M.getGroupState = getGroupState

return M
