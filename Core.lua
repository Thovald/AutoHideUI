local _, Private = ...
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")
Private.Main = {}
Private.Config = {}
Private.Frames = {}
Private.Fading = {}
Private.FrameFinder = {}
Private.MouseoverAreas = {}
Private.Changelog = {}

-- namespaces for functions that are called between files
local Main = Private.Main
local Config = Private.Config
local Frames = Private.Frames
local Fading = Private.Fading
local MouseoverAreas = Private.MouseoverAreas
local internal = {}
local DB_SCHEMA_VERSION = 1

-- unlike systemFrame, Main.frame's events are registered based on which conditions are enabled
Main.frame = CreateFrame("Frame")
local systemFrame = CreateFrame("Frame")
systemFrame:RegisterEvent("PLAYER_LOGIN")
systemFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
systemFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

-- these are what we read and write to on runtime
Main.activeStrings = {} -- [frameString] = { frames = {frameObject, ...}, args = {} , group = reference to parent group}
Main.activeGroups = {} -- [1] = { frames = {frameObject, ...}, config = {}, states = {}, conditions = {combat = {}, ...}}
Main.activeFrames = {} -- {frameObject = {isInUse = bool, isCustom = bool, group = groupTable, frameString = string}, ...}

-- used to only create and run mouseover stuff where it's needed
local mouseoverTicker
local mouseoverFrames = {} -- {frameObject = groupTable, ...}
local mouseoverGroups = {} -- {groupTable = true, ...}
local MOUSE_TICKER_INTERVAL = 0.125

-- health-check stuff
local TIME_TO_FLAG_FULL_HEALTH = 3
local healthStates = {
    player = {
        isMissingHealth = false,
        maxHealthChangeTime = 0,
        healthTimer = nil,
    },
    party = {
        isMissingHealth = false,
        maxHealthChangeTime = 0,
        healthTimer = nil,
    }
}
local PARTY_UNITS = {
    party1 = true,
    party2 = true,
    party3 = true,
    party4 = true,
}

local INSTANCE_TYPE_MAPPING = {
    pvp = "instanceBattleground",
    arena = "instanceArena",
    party = "instanceDungeon",
    raid = "instanceRaid",
    scenario = "instanceScenario",
    neighborhood = "instanceNeighborhood",
    interior = "instanceHousing",
}

Main.DEFAULT_STATES = {
    startAlpha = 1,
    endAlpha = 1,
    fadeEndTime = 0, -- if GetTime() < fadeEndTime we measure and use currentAlpha as startAlpha
    lastMouseover = nil, -- mouseover is polled constantly. only updating when current and last are different.
    fadeMode = "",
    priorityFade = false, -- if fadeMode == "OUT" and priority, we fade out without delay
    activeConditions = { -- key: name of condition -- value: false or alpha of condition
        normal = {},
        priority = {},
    },
}

Main.inCombat = InCombatLockdown()
local isMounted = IsMounted()
local isFlying = IsFlying()
local isGliding = C_PlayerInfo.GetGlidingInfo()
local isFlyingTicker
local lastLowHealthVis = LowHealthFrame:IsVisible()
local lastInstanceCheck = 0
local INSTANCE_THROTTLE = 1
Main.runAfterCombat = {} -- {{fn, arg1, arg2, ...}, ...}
Main.framesThatToggleVisibility = {} -- {frame = {threshold = 0.1, group = groupTable }, ...}
Main.helperFrames = {} -- generic helper frames for mouseover

local DRUID_FORMS= {
    {
        [3] = true, -- Travel/Mount Form
        [4] = true, -- Aquatic Form
        [27] = true, -- Swift Flight Form
        [29] = true, -- Flight Form
    },
    {
        [3] = true, -- Travel/Mount Form
        [27] = true, -- Swift Flight Form
        [29] = true, -- Flight Form
    },
    {}, -- user selected "None"
}

local GetTime, pairs, ipairs, C_Timer
    = GetTime, pairs, ipairs, C_Timer
local IsInInstance, IsMounted, GetShapeshiftFormID, UnitInVehicle, HasOverrideActionBar
    = IsInInstance, IsMounted, GetShapeshiftFormID, UnitInVehicle, C_ActionBar.HasOverrideActionBar
local UnitCastingInfo, UnitChannelInfo, IsResting, IsFlying, UnitExists, UnitCanAttack
    = UnitCastingInfo, UnitChannelInfo, IsResting, IsFlying, UnitExists, UnitCanAttack

------------------
-- Setup
------------------

function Private:OnProfileChanged()
    Config.SetSelectedGroup(true)
end

local function InitDB()
    local defaultProfile = Config.GetDefaultProfile()
    Private.db = LibStub("AceDB-3.0"):New("AutoHideUIDB", defaultProfile, true)

    Private.db.RegisterCallback(Private, "OnProfileChanged", "OnProfileChanged")
    Private.db.RegisterCallback(Private, "OnProfileCopied", "OnProfileChanged")
    Private.db.RegisterCallback(Private, "OnProfileReset", "OnProfileChanged")

    Config.RegisterOptions()
end

local function InitOptions()
    Config.SetSelectedGroup()
    Config.CreateOptionsMenu()
end

local function UpdateVersion()
    Private.db.global.version_last = Private.db.global.version or "1.0.0"
    Private.db.global.version = C_AddOns.GetAddOnMetadata("AutoHideUI", "version")
end

local function RegisterEventsInCondition(condition)
    local events
    local parents = {}

    for _, info in ipairs(Config.CONDITION_DEFINITIONS) do
        if info.name == condition and info.events then
            events = info.events
            break
        elseif info.type == "parent" then
            parents[info.name] = info
        elseif info.name == condition and info.type == "child" then
            events = parents[info.parent].events
        end
    end

    for _, event in pairs(events) do
        Main.frame:RegisterEvent(event)
    end
end

local function RegisterEventsInGroup(group)
    for condition, info in pairs(group.conditions) do
        if info.enabled then
            RegisterEventsInCondition(condition)
        end
    end
end

local function RegisterAllEvents()
    Main.frame:UnregisterAllEvents()
    for _, group in ipairs(Main.activeGroups) do
        RegisterEventsInGroup(group)
    end
end

local function UnregisterAllEvents()
    Main.frame:UnregisterAllEvents()
end

local function ResetGroupStates(states)
    for k, v in pairs(states) do
        if type(v) == "table" then
            states[k] = CopyTable(Main.DEFAULT_STATES[k])
        else
            states[k] = Main.DEFAULT_STATES[k]
        end
    end
end

local function ResetAllGroupStates()
    for _, group in ipairs(Main.activeGroups) do
        ResetGroupStates(group.states)
    end
end

local function GetGroupsForMouseoverFrame(frameGroup, globalGroups)
    -- returns which groups should be triggered when mousing over frames of this group
    local groupList = {frameGroup}

    for group in pairs(globalGroups) do
        if group ~= frameGroup then
            tinsert(groupList, group)
        end
    end

    return groupList
end

function Main.CreateMouseoverLists()
    wipe(mouseoverFrames)
    wipe(mouseoverGroups)
    local globalGroups = {}

    for _, group in ipairs(Main.activeGroups) do
        if group.conditions.mouseover.enabled then
            mouseoverGroups[group] = true
        end

        -- means this group responds to mouseovers events from any group
        if group.conditions.mouseover.trigger == 2 then
            globalGroups[group] = true
        end
    end

    for group in pairs(mouseoverGroups) do
        for _, frame in pairs(group.frames) do
            if not frame:IsAnchoringRestricted(group) then
                mouseoverFrames[frame] = GetGroupsForMouseoverFrame(group, globalGroups)
            end
        end
    end

    for _, mouseoverArea in pairs(MouseoverAreas.ActiveAreas) do
        local group = Main.activeGroups[mouseoverArea.group]
        mouseoverFrames[mouseoverArea] = GetGroupsForMouseoverFrame(group, globalGroups)
    end
end

function Main.GetMouseoverFrames()
    return mouseoverFrames
end

local function ResetStates()
    Fading.WipeFadeQueue()
    ResetAllGroupStates()
    healthStates.player.isMissingHealth = false
    healthStates.party.isMissingHealth = false
    Fading.ResetPendingFades()
end

local function CancelTickers()
    if mouseoverTicker then
        mouseoverTicker:Cancel()
        mouseoverTicker = nil
    end

    if isFlyingTicker then
        isFlyingTicker:Cancel()
        isFlyingTicker = nil
    end
end

local function ClearQueues()
    Fading.ResetPendingFades()
    Fading.WipeFadeQueue()
    wipe(Main.runAfterCombat)
end

local function ResetAddon()
    Frames.ResetFrames()
    MouseoverAreas.ClearAreas()
    ResetStates()
    wipe(Main.framesThatToggleVisibility)
end

local function InitAddon()
    Frames.InitFrames()
    Fading.ResetPendingFades()
    RegisterAllEvents()
    MouseoverAreas.CreateAreas()
    Main.CreateMouseoverLists()
    internal.CreateMouseoverTicker()
    internal.UpdateAllConditions()
    Fading.SetAllAlpha()
    Frames.ToggleHelperFrames()
end

function Main.SuspendAddon()
    UnregisterAllEvents()
    CancelTickers()
    ClearQueues()
    Fading.SetAllAlpha(1)
end

function Main.ResumeAddon()
    ResetAddon()
    InitAddon()
end

function Main.GetErrorTitleString()
    return "|cff80ffffAuto Hide UI: |r"
end

function Main.ColorString(string, clr)
    local clrTable = {
        red = "|cffff3b3b",
        green = "|cff3bff3b",
        blue = "|cff80ffff",
        gold = "|cFFFFD100",
    }

    local clrString = clrTable[clr]
    if clrString then
        return clrString .. string .. "|r"
    else
        return string
    end
end

local function RunAfterCombatQueue()
    for _, entry in ipairs(Main.runAfterCombat) do
        local func = entry[1]
        if type(func) == "function" then
            func(unpack(entry, 2))
        end
    end
    wipe(Main.runAfterCombat)
end

local function GetConditionRelationships(conditionName)
    for _, conditionInfo in ipairs(Config.CONDITION_DEFINITIONS) do
        if conditionInfo.name == conditionName then
            return conditionInfo.type, conditionInfo.parent
        end
    end
end

function Main.GetConditionsSettings(conditionsDB)
    -- some conditions may inherit their settings from their parent-condition.
    -- or they may use their own override settings.
    -- so we can't use the db directly and instead need to determine the actual values first.
    local conditions = {}

    for conditionName, conditionInfo in pairs(conditionsDB) do
        local conditionType, parentName = GetConditionRelationships(conditionName)

        if conditionType == "default" then
            conditions[conditionName] = CopyTable(conditionInfo)
        elseif conditionType == "child" then
            local childInfo
            local parentInfo = conditionsDB[parentName]
            local isChildEnabled = conditionInfo.enabled and parentInfo.enabled
            local useOverride = conditionInfo.customize

            if isChildEnabled and not useOverride then
                -- inheriting parent settings
                childInfo = CopyTable(parentInfo)
            elseif isChildEnabled and useOverride then
                -- using child's override settings
                childInfo = CopyTable(conditionInfo)
            else
                -- child is not enabled
                childInfo = CopyTable(conditionInfo)
                childInfo.enabled = false
            end

            conditions[conditionName] = childInfo
        end
    end

    return conditions
end

------------------
-- Repairing DB
------------------

local MigrateDB = {
    -- when parent/child conditions were introduced
    [1] = function(profile)
        local OLD_CONDITION_DEFAULTS = {
            housing        = { enabled = false, alpha = 0, priority = true },
            instance       = { enabled = true,  alpha = 1, priority = false },
            targetFriendly = { enabled = true,  alpha = 1, priority = false, softTarget = false },
            targetHostile  = { enabled = true,  alpha = 1, priority = false, softTarget = false },
        }

        local function ResolveOldCondition(c, name)
            local result = CopyTable(OLD_CONDITION_DEFAULTS[name])
            if c[name] then
                for k, v in pairs(c[name]) do
                    result[k] = v
                end
            end
            return result
        end

        local function UpdateGroup(group)
            local c = group.conditions
            if not c then
                -- is using defaults
                return
            end

            local housing  = ResolveOldCondition(c, "housing")
            local instance = ResolveOldCondition(c, "instance")
            local tFriendly = ResolveOldCondition(c, "targetFriendly")
            local tHostile  = ResolveOldCondition(c, "targetHostile")

            -- instance and housing
            c.instanceNeighborhood = CopyTable(housing)
            c.instanceHousing      = CopyTable(housing)

            if housing.alpha ~= instance.alpha or housing.priority ~= instance.priority then
                c.instanceNeighborhood.customize = true
                c.instanceHousing.customize      = true
            else
                c.instanceNeighborhood.customize = false
                c.instanceHousing.customize      = false
            end

            if housing.enabled and not instance.enabled then
                c.instance = c.instance or {}
                c.instance.enabled = true
                for _, name in ipairs({ "instanceDungeon", "instanceRaid", "instanceBattleground", "instanceArena", "instanceScenario" }) do
                    c[name] = c[name] or {}
                    c[name].enabled = false
                end
            end

            c.housing = nil

            -- target and focus
            local targetEnabled = tFriendly.enabled or tHostile.enabled

            local targetSettingsMatch = tFriendly.alpha == tHostile.alpha
                            and tFriendly.priority  == tHostile.priority
                            and tFriendly.softTarget == tHostile.softTarget

            if targetSettingsMatch then
                c.target = CopyTable(tFriendly)
                c.focus  = CopyTable(tFriendly)
                c.targetFriendly = c.targetFriendly or {}
                c.targetHostile  = c.targetHostile  or {}
                c.targetFriendly.customize = false
                c.targetHostile.customize  = false
                c.focusFriendly = CopyTable(tFriendly)
                c.focusHostile  = CopyTable(tHostile)
                c.focusFriendly.customize = false
                c.focusHostile.customize  = false
            else
                c.target = CopyTable(Config.GetDefaultConditionByName("target").db)
                c.focus  = CopyTable(Config.GetDefaultConditionByName("focus").db)
                c.targetFriendly = c.targetFriendly or {}
                c.targetHostile  = c.targetHostile  or {}
                c.targetFriendly.customize = true
                c.targetHostile.customize  = true
                c.focusFriendly = CopyTable(tFriendly)
                c.focusHostile  = CopyTable(tHostile)
                c.focusFriendly.customize = true
                c.focusHostile.customize  = true
            end

            c.target.enabled = targetEnabled
            c.focus.enabled  = targetEnabled
            c.focusFriendly.softTarget = nil
            c.focusHostile.softTarget  = nil
        end

        local newProfile = {
            groups= {},
            manualControl = {}
        }

        for i, group in ipairs(profile) do
            UpdateGroup(group)
            tinsert(newProfile.groups, group)
        end

        return newProfile
    end
}

local function RepairDB()
    -- remove nil groups from each profile
    -- these can occur from incomplete deletions or legacy corruption
    for profileKey, profileData in pairs(Private.db.profiles) do
        if profileData.groups then
            local cleanedGroups = {}

            -- copy only non-nil groups to new table
            for _, group in ipairs(profileData.groups) do
                if group then
                    tinsert(cleanedGroups, group)
                end
            end

            Private.db.profiles[profileKey].groups = cleanedGroups
        end
    end

    Config.CheckGroupsForMissingEntries()
end

local function UpdateDB()
    local lastSchemaVersion = Private.db.global.db_schema or 0

    for i = lastSchemaVersion + 1, DB_SCHEMA_VERSION do
        local migration = MigrateDB[i]
        if migration then
            -- migrating every profile
            for profileName, profileData in pairs(Private.db.profiles) do
                local newProfile = migration(profileData)
                if newProfile then
                    Private.db.profiles[profileName] = newProfile
                end
            end
        end
    end

    Private.db.global.db_schema = DB_SCHEMA_VERSION
end

------------------
-- Conditions
------------------

local function UpdateActiveConditions(group, condition, value)
    if not group.conditions[condition].enabled then
        return
    end

    local activeConditions = group.states.activeConditions

    if value then
        local conditionData = group.conditions[condition]
        local alpha = conditionData.alpha
        local priority = conditionData.priority

        if priority then
            activeConditions.priority[condition] = alpha
        else
            activeConditions.normal[condition] = alpha
        end
    else
        activeConditions.priority[condition] = false
        activeConditions.normal[condition] = false
    end
end

local function UpdateConditionForAllGroups(condition, value)
    for i, group in ipairs(Main.activeGroups) do
        UpdateActiveConditions(group, condition, value)
    end
end

local function ConditionCombat()
    UpdateConditionForAllGroups("combat", Main.inCombat)
end

local function ConditionTarget(unitToken)
    local isFriendly, isHostile = false, false

    if UnitExists(unitToken) then
        if UnitCanAttack("player", unitToken) then
            isHostile = true
        else
            isFriendly = true
        end
    end

    UpdateConditionForAllGroups(unitToken .. "Hostile", isHostile)
    UpdateConditionForAllGroups(unitToken .. "Friendly", isFriendly)
end

local function ConditionSoftTarget()
    if UnitExists("target") then
        return
    end

    local hasHostileSoftTarget, hasFriendlySoftTarget = false, false

    for _, group in pairs(Main.activeGroups) do
        if group.conditions.targetHostile.softTarget and UnitExists("softenemy") then
            hasHostileSoftTarget = true
        elseif group.conditions.targetFriendly.softTarget and UnitExists("softfriend") then
            -- Action Targeting doesn't turn on the CVar for friendly targets.
            -- PLAYER_SOFT_INTERACT_CHANGED fires on them regardless of Action Targeting setting.
            hasFriendlySoftTarget = true
        end

        UpdateActiveConditions(group, "targetHostile", hasHostileSoftTarget)
        UpdateActiveConditions(group, "targetFriendly", hasFriendlySoftTarget)
    end
end

local function ConditionInteractable(canInteract)
    local softTarget = UnitExists("softinteract")
    for _, group in pairs(Main.activeGroups) do
        if group.conditions.interactable.excludeNPCs and canInteract then
            canInteract = not softTarget
        else
            canInteract = canInteract or softTarget
        end
        UpdateActiveConditions(group, "interactable", canInteract)
    end
end

local function ConditionInstance()
    local isInInstance, currentInstanceType = IsInInstance()

    if not isInInstance and currentInstanceType ~= "scenario" then
        for _, instanceCondition in pairs(INSTANCE_TYPE_MAPPING) do
            UpdateConditionForAllGroups(instanceCondition, false)
        end
    else
        for instanceType, instanceCondition in pairs(INSTANCE_TYPE_MAPPING) do
            if instanceType == currentInstanceType then
                UpdateConditionForAllGroups(instanceCondition, true)
            else
                UpdateConditionForAllGroups(instanceCondition, false)
            end
        end
    end

end

local function ConditionMouseover()
    -- checking if mouse is hovering over a relevant frame.
    local currentMouseover = false
    local mouseoverChanged, groupsToUpdate
    for frame, groups in pairs(mouseoverFrames) do
        if frame:IsMouseOver() and frame:IsVisible() then
            currentMouseover = true
            groupsToUpdate = groups
            break
        end
    end

    -- only returning true when there was a change to mouseover, which then prompts an update. 
    if groupsToUpdate then
        for _, group in ipairs(groupsToUpdate) do
            if currentMouseover ~= group.states.lastMouseover then
                group.states.lastMouseover = currentMouseover
                UpdateActiveConditions(group, "mouseover", currentMouseover)
                mouseoverChanged = true
            end
        end
        return mouseoverChanged, groupsToUpdate
    else
        groupsToUpdate = {}
        for group, _ in pairs(mouseoverGroups) do
            if group.states.lastMouseover then
                group.states.lastMouseover = false
                UpdateActiveConditions(group, "mouseover", false)
                tinsert(groupsToUpdate, group)
                mouseoverChanged = true
            end
        end
        return mouseoverChanged, groupsToUpdate
    end

end

local function ConditionFlying()
    for _, group in ipairs(Main.activeGroups) do
        local steady = isFlying and group.conditions.flying.style ~= 1
        local skyriding = isGliding and group.conditions.flying.style ~= 2
        UpdateActiveConditions(group, "flying", steady or skyriding)
    end
end

local function StartIsFlyingTicker()
    if isFlyingTicker then
        return
    end

    isFlyingTicker = C_Timer.NewTicker(0.25, function()
        if isFlying ~= IsFlying() then
            isFlying = not isFlying
            ConditionFlying()
            Fading.FadeAllGroups()
        end
    end)
end

local function HandleIsFlyingTicker()
    if not isMounted then
        if isFlyingTicker then
            isFlyingTicker:Cancel()
            isFlyingTicker = nil
        end
        return
    end

    local _, canGlide = C_PlayerInfo.GetGlidingInfo()
    for i, group in ipairs(Main.activeGroups) do
        if group.conditions.flying.enabled and group.conditions.flying.style ~= 1 and not canGlide then
            StartIsFlyingTicker()
            return
        end
    end
end

local function ConditionMounted()
    isMounted = IsMounted()
    UpdateConditionForAllGroups("mounted", isMounted)
    RunNextFrame(HandleIsFlyingTicker)
end

local function ConditionShapeshift()
    local shapeId = GetShapeshiftFormID()

    for _, group in ipairs(Main.activeGroups) do
        local formsKey = group.conditions.mounted.druidForms
        local validShapes = DRUID_FORMS[formsKey]
        local isMountShape = validShapes[shapeId]
        UpdateActiveConditions(group, "mounted", isMounted or isMountShape)
    end

    RunNextFrame(HandleIsFlyingTicker)
end

local function ConditionHealth()
    for _, group in ipairs(Main.activeGroups) do
        local healthState
        if group.conditions.health.style == 1 then
            healthState = lastLowHealthVis
        elseif group.conditions.health.style == 2 then
            healthState = healthStates.player.isMissingHealth
        elseif group.conditions.health.style == 3 then
            healthState = healthStates.party.isMissingHealth
        else
            healthState = healthStates.player.isMissingHealth or healthStates.party.isMissingHealth
        end

        UpdateActiveConditions(group, "health", healthState)
    end
end

local function CheckLowHealthChange()
    local currentLowHealthVis = LowHealthFrame:IsVisible()
    if lastLowHealthVis ~= currentLowHealthVis then
        lastLowHealthVis = currentLowHealthVis
        return true
    else
        return false
    end
end

local function CheckMissingHealthChange(key)
    local currentTime = GetTime()
    if currentTime == healthStates[key].maxHealthChangeTime then
        return false
    end

    if healthStates[key].healthTimer then
        ---@diagnostic disable-next-line: undefined-field
        healthStates[key].healthTimer:Cancel()
    end

    healthStates[key].isMissingHealth = true

    healthStates[key].healthTimer = C_Timer.NewTimer(TIME_TO_FLAG_FULL_HEALTH, function()
        healthStates[key].isMissingHealth = false
        ConditionHealth()
        Fading.offsetForFadeDelay = TIME_TO_FLAG_FULL_HEALTH * -1
        Fading.FadeAllGroups()
        Fading.offsetForFadeDelay = 0
    end)

    return true
end

local function ConditionVehicle()
    UpdateConditionForAllGroups("inVehicle", UnitInVehicle("player") or HasOverrideActionBar())
end

local function ConditionCasting(castState)
    local isCasting

    if castState ~= nil then
        isCasting = castState
    else
        isCasting = UnitCastingInfo("player") or UnitChannelInfo("player")
    end

    UpdateConditionForAllGroups("casting", isCasting)
end

local function ConditionResting()
    UpdateConditionForAllGroups("resting", IsResting())
end

function internal.UpdateAllConditions()
    ConditionCombat()
    ConditionTarget("target")
    ConditionTarget("focus")
    ConditionSoftTarget()
    ConditionInteractable()
    ConditionInstance()
    ConditionMounted()
    ConditionShapeshift()
    ConditionMouseover()
    ConditionVehicle()
    ConditionCasting()
    ConditionResting()
    ConditionHealth()
    ConditionFlying()
end

------------------
-- Events
------------------

local function OnLogin()
    -- deferred to ensure all AddOn frames have been created.
    C_Timer.After(3, function()
        InitDB()
        UpdateVersion()
        UpdateDB()
        RepairDB()
        InitOptions()
        InitAddon()
    end)

    -- on very slow logins minimap pins don't remain hidden.
    C_Timer.After(10, function()
        Fading.UpdateAllFrameVisibility()
    end)
end

local function OnTargetChange(unitToken)
    ConditionTarget(unitToken)
    Fading.FadeAllGroups()
end

local function OnSoftTargetChange()
    ConditionSoftTarget()
    Fading.FadeAllGroups()
end

local function OnInteractableChange(_, newTarget)
    if newTarget then
        ConditionInteractable(true)
    else
        UpdateConditionForAllGroups("interactable", false)
    end
    Fading.FadeAllGroups()
end

local function OnCombatChange(combatStatus)
    Main.inCombat = combatStatus

    -- we are running this here as well, because it's not guaranteed that both frames fire events in the order we want.
    if Main.inCombat then
        wipe(Main.runAfterCombat)
    else
        RunAfterCombatQueue()
    end

    ConditionCombat()
    Fading.FadeAllGroups()
end

local function OnCombatStart()
    wipe(Main.runAfterCombat)
    local setVisibilityToValue = true
    Fading.UpdateAllFrameVisibility(setVisibilityToValue)
    Main.inCombat = true
end

local function OnCombatEnd()
    Main.inCombat = false
    Fading.UpdateAllFrameVisibility()
    RunAfterCombatQueue()
end

local function OnMouseover()
    local mouseoverChanged, groups = ConditionMouseover()
    if mouseoverChanged then
        for _, group in ipairs(groups) do
            Fading.FadeGroup(group)
        end
    end
end

function internal.CreateMouseoverTicker()
    if (not mouseoverTicker) and next(mouseoverFrames) then
        mouseoverTicker = C_Timer.NewTicker(MOUSE_TICKER_INTERVAL, OnMouseover)
        return
    end
end

local function OnInstanceChange()
    local currentTime = GetTime()
    if currentTime - lastInstanceCheck < INSTANCE_THROTTLE then
        return
    end
    ResetStates()
    internal.UpdateAllConditions()
    Fading.SetAllAlpha()
    lastInstanceCheck = currentTime
end

local function OnMountChange()
    ConditionMounted()
    Fading.FadeAllGroups()
end

local function OnShapeshift()
    ConditionShapeshift()
    Fading.FadeAllGroups()
end

local function OnGlideChange(val)
    isGliding = val
    ConditionFlying()
    Fading.FadeAllGroups()
end

local function OnVehicleChange()
    ConditionVehicle()
    Fading.FadeAllGroups()
end

local function OnActionbarChange()
    ConditionVehicle()
    Fading.FadeAllGroups()
end

local function OnHealthChange(unit)
    local lowHealthChanged, missingHealthChanged

    if unit == "player" then
        lowHealthChanged = CheckLowHealthChange()
        missingHealthChanged = CheckMissingHealthChange("player")
    elseif PARTY_UNITS[unit] then
        missingHealthChanged = CheckMissingHealthChange("party")
    else
        return
    end

    if lowHealthChanged or missingHealthChanged then
        ConditionHealth()
        Fading.FadeAllGroups()
    end
end

local function OnMaxHealthChange(unit)
    if unit == "player" then
        healthStates.player.maxHealthChangeTime = GetTime()
    elseif PARTY_UNITS[unit] then
        healthStates.party.maxHealthChangeTime = GetTime()
    end
end

local function OnMaxHealthModifierChange(unit)
    if unit == "player" then
        healthStates.player.maxHealthChangeTime = GetTime()
    elseif PARTY_UNITS[unit] then
        healthStates.party.maxHealthChangeTime = GetTime()
    end
end

local function OnCastStart(unit)
    if unit ~= "player" then
        return
    end

    ConditionCasting(true)
    Fading.FadeAllGroups()
end

local function OnCastEnd(unit)
    if unit ~= "player" then
        return
    end

    ConditionCasting(false)
    Fading.FadeAllGroups()
end

local function OnRestingChange()
    ConditionResting()
    Fading.FadeAllGroups()
end

------------------
-- Event Handler
------------------

local EVENT_HANDLER = {
    PLAYER_TARGET_CHANGED = function() OnTargetChange("target") end,
    PLAYER_FOCUS_CHANGED = function() OnTargetChange("focus") end,
    PLAYER_SOFT_ENEMY_CHANGED = OnSoftTargetChange,
    PLAYER_SOFT_FRIEND_CHANGED = OnSoftTargetChange,
    PLAYER_SOFT_INTERACT_CHANGED = OnInteractableChange,
    PLAYER_REGEN_DISABLED = function() OnCombatChange(true) end,
    PLAYER_REGEN_ENABLED = function() OnCombatChange(false) end,
    PLAYER_ENTERING_WORLD = OnInstanceChange,
    LOADING_SCREEN_DISABLED = OnInstanceChange,
    ZONE_CHANGED_NEW_AREA = OnInstanceChange,
    WORLD_CURSOR_TOOLTIP_UPDATE = OnMouseover,
    UPDATE_MOUSEOVER_UNIT = OnMouseover,
    PLAYER_MOUNT_DISPLAY_CHANGED = OnMountChange,
    UPDATE_SHAPESHIFT_FORM = OnShapeshift,
    PLAYER_IS_GLIDING_CHANGED = OnGlideChange,
    UNIT_ENTERED_VEHICLE = OnVehicleChange,
    UNIT_EXITED_VEHICLE = OnVehicleChange,
    UPDATE_OVERRIDE_ACTIONBAR = OnActionbarChange,
    UNIT_HEALTH = OnHealthChange,
    UNIT_MAXHEALTH = OnMaxHealthChange,
    UNIT_MAX_HEALTH_MODIFIERS_CHANGED = OnMaxHealthModifierChange,
    UNIT_SPELLCAST_START = OnCastStart,
    UNIT_SPELLCAST_CHANNEL_START = OnCastStart,
    UNIT_SPELLCAST_STOP = OnCastEnd,
    UNIT_SPELLCAST_CHANNEL_STOP = OnCastEnd,
    PLAYER_UPDATE_RESTING = OnRestingChange,
}

local SYSTEM_EVENT_HANDLER = {
    PLAYER_LOGIN = OnLogin,
    PLAYER_REGEN_ENABLED = OnCombatEnd,
    PLAYER_REGEN_DISABLED = OnCombatStart,
}

function systemFrame:OnEvent(event, ...)
    SYSTEM_EVENT_HANDLER[event]()
end

function Main.frame:OnEvent(event, ...)
    EVENT_HANDLER[event](...)
end

Main.frame:SetScript("OnEvent", Main.frame.OnEvent)
systemFrame:SetScript("OnEvent", systemFrame.OnEvent)

