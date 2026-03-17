local _, Private = ...
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")
Private.Main = {}
Private.Config = {}
Private.Frames = {}
Private.Fading = {}
Private.FrameFinder = {}
Private.isAceHooked = false

-- namespaces for functions that are called between files
local Main = Private.Main
local Config = Private.Config
local Frames = Private.Frames
local Fading = Private.Fading
local internal = {}

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
local isMissingHealth = false
local maxHealthChangeTime = 0
local healthTimer

Main.inCombat = InCombatLockdown()
local hasHostileTarget, hasFriendlyTarget, hasHostileFocus, hasFriendlyFocus
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

local GetTime, pairs, ipairs, max, min, C_Timer
    = GetTime, pairs, ipairs, max, min, C_Timer
local IsInInstance, InCombatLockdown, IsOnNeighborhoodMap, IsInsideHouse, IsMounted
    = IsInInstance, InCombatLockdown, C_Housing.IsOnNeighborhoodMap, C_Housing.IsInsideHouse, IsMounted
local GetShapeshiftFormID, UnitInVehicle, UnitCastingInfo, UnitChannelInfo, IsResting, IsFlying, UnitExists, UnitCanAttack
    = GetShapeshiftFormID, UnitInVehicle, UnitCastingInfo, UnitChannelInfo, IsResting, IsFlying, UnitExists, UnitCanAttack

------------------
-- Setup
------------------

function Private:OnProfileChanged()
    Config.SetSelectedGroup(true)
end

local function InitDB()
    local defaultGroup = Config.GetDefaultGroup(L["name_defaultGroup"])
    local defaultProfile = { profile = {defaultGroup} }

    Private.db = LibStub("AceDB-3.0"):New("AutoHideUIDB", defaultProfile, true)
    Config.CheckGroupsForMissingEntries(defaultGroup)

    Private.db.RegisterCallback(Private, "OnProfileChanged", "OnProfileChanged")
    Private.db.RegisterCallback(Private, "OnProfileCopied", "OnProfileChanged")
    Private.db.RegisterCallback(Private, "OnProfileReset", "OnProfileChanged")

    Config.RegisterOptions()
end

local function InitOptions()
    Config.SetSelectedGroup()
    Config.CreateOptionsMenu()
end

local function RegisterEventsInCondition(condition)
    for _, info in pairs(Config.CONDITION_DEFINITIONS) do
        if info.name == condition then
            for _, event in pairs(info.events) do
                Main.frame:RegisterEvent(event)
            end
        end
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
            states[k] = CopyTable(Config.DEFAULT_STATES[k])
        else
            states[k] = Config.DEFAULT_STATES[k]
        end
    end
end

local function ResetAllGroupStates()
    for _, group in ipairs(Main.activeGroups) do
        ResetGroupStates(group.states)
    end
end

local function CreateMouseoverLists()
    wipe(mouseoverFrames)
    wipe(mouseoverGroups)
    for _, group in ipairs(Main.activeGroups) do
        if group.conditions.mouseover.enabled then
            mouseoverGroups[group] = true
            for _, frame in pairs(group.frames) do
                if not frame:IsAnchoringRestricted() then
                    mouseoverFrames[frame] = group
                end
            end
        end
    end
end

local function ResetStates()
    ResetAllGroupStates()
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
    ResetStates()
    wipe(Main.framesThatToggleVisibility)
end

local function InitAddon()
    Frames.InitFrames()
    Fading.ResetPendingFades()
    RegisterAllEvents()
    CreateMouseoverLists()
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

local function UpdateTargetStatesForUnitToken(unitToken, valHostile, valFriendly)
    if unitToken == "target" then
        hasHostileTarget = valHostile
        hasFriendlyTarget = valFriendly
    elseif unitToken == "focus" then
        hasHostileFocus = valHostile
        hasFriendlyFocus = valFriendly
    end
end

local function GetOtherTargetStates(unitToken)
    if unitToken == "target" then
        return hasHostileFocus, hasFriendlyFocus
    elseif unitToken == "focus" then
        return hasHostileTarget, hasFriendlyTarget
    end
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
    local otherHostileTarget, otherFriendlyTarget = GetOtherTargetStates(unitToken)
    local thisHostileTarget, thisFriendlyTarget

    if UnitExists(unitToken) then
        if not otherHostileTarget and UnitCanAttack("player", unitToken) then
            thisHostileTarget = true
        else
            thisFriendlyTarget = true
        end
    end
    
    UpdateTargetStatesForUnitToken(unitToken, thisHostileTarget, thisFriendlyTarget)

    UpdateConditionForAllGroups("targetHostile", thisHostileTarget or otherHostileTarget)
    UpdateConditionForAllGroups("targetFriendly", thisFriendlyTarget or otherFriendlyTarget)
end

local function ConditionSoftTarget()
    local anyTarget = hasHostileTarget or hasHostileFocus or hasFriendlyTarget or hasFriendlyFocus

    if anyTarget then
        return
    end

    local hasHostileSoftTarget, hasFriendlySoftTarget

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
    local isInInstance = IsInInstance()
    local isHousing = IsOnNeighborhoodMap() or IsInsideHouse()
    UpdateConditionForAllGroups("instance", isInInstance and not isHousing)
end

local function ConditionMouseover()
    -- checking if mouse is hovering over a relevant frame.
    local currentMouseover = false
    local mouseoverGroup
    for frame, group in pairs(mouseoverFrames) do
        if frame:IsMouseOver() and frame:IsVisible() then
            currentMouseover = true
            mouseoverGroup = group
            break
        end
    end

    -- only returning true when there was a change to mouseover, which then prompts an update. 
    if mouseoverGroup and currentMouseover ~= mouseoverGroup.states.lastMouseover then
        mouseoverGroup.states.lastMouseover = currentMouseover
        UpdateActiveConditions(mouseoverGroup, "mouseover", currentMouseover)
        return true, mouseoverGroup
    elseif not mouseoverGroup then
        for group, _ in pairs(mouseoverGroups) do
            if group.states.lastMouseover then
                group.states.lastMouseover = false
                UpdateActiveConditions(group, "mouseover", false)
                return true, group
            end
        end
    end

    return false
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
    isMounted = DRUID_FORMS[2][shapeId]
    RunNextFrame(HandleIsFlyingTicker)

    for _, group in ipairs(Main.activeGroups) do
        local formsKey = group.conditions.mounted.druidForms
        local validShapes = DRUID_FORMS[formsKey]
        local isMountShape = validShapes[shapeId]
        UpdateActiveConditions(group, "mounted", isMountShape)
    end
end

local function ConditionHealth()
    for _, group in ipairs(Main.activeGroups) do
        local healthState 
        if group.conditions.health.style == 1 then
            healthState = lastLowHealthVis
        else 
            healthState = isMissingHealth
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

local function CheckMissingHealthChange()
    local currentTime = GetTime()
    if currentTime == maxHealthChangeTime then
        return false
    end

    if healthTimer then
        healthTimer:Cancel()
    end

    isMissingHealth = true

    healthTimer = C_Timer.NewTimer(TIME_TO_FLAG_FULL_HEALTH, function()
        isMissingHealth = false
        ConditionHealth()
        Fading.offsetForFadeDelay = TIME_TO_FLAG_FULL_HEALTH * -1
        Fading.FadeAllGroups()
        Fading.offsetForFadeDelay = 0
    end)

    return true
end

local function ConditionVehicle()
    UpdateConditionForAllGroups("inVehicle", UnitInVehicle("player"))
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
    C_Timer.After(1, function()
        InitDB()
        InitOptions()
        InitAddon()
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
    local mouseoverChanged, group = ConditionMouseover()
    if mouseoverChanged then
        Fading.FadeGroup(group)
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

local function OnHealthChange(unit)
    if unit ~= "player" then
        return
    end

    local lowHealthChanged = CheckLowHealthChange()
    local missingHealthChanged = CheckMissingHealthChange()

    if lowHealthChanged or missingHealthChanged then
        ConditionHealth()
        Fading.FadeAllGroups()
    end
end

local function OnMaxHealthChange(unit)
    if unit ~= "player" then
        return
    end
    maxHealthChangeTime = GetTime()
end

local function OnMaxHealthModifierChange(unit)
    if unit ~= "player" then
        return
    end
    maxHealthChangeTime = GetTime()
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

