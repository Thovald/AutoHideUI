local _, Private = ...
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")
Private.main = {}
Private.config = {}
Private.isAceHooked = false

local db
-- namespaces for functions that are called between files
local main = Private.main
local config = Private.config
-- namespace for functions that are referenced before they are defined
local internal = {}

-- unlike systemFrame, main.frame's events are registered based on which conditions are enabled
main.frame = CreateFrame("Frame")
local systemFrame = CreateFrame("Frame")
systemFrame:RegisterEvent("PLAYER_LOGIN")
systemFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
systemFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

-- these are what we read and write to on runtime
local activeStrings = {} -- [frameString] = { frames = {frameObject, ...}, args = {} , group = reference to parent group}
local activeGroups = {} -- [1] = { frames = {frameObject, ...}, config = {}, states = {}, conditions = {combat = {}, ...}}
local activeFrames = {} -- {frameObject = {isInUse = bool, group = groupTable, frameString = string}, ...}

-- used to only create and run mouseover stuff where it's needed
local mouseoverTicker
local mouseoverFrames = {} -- {frameObject = groupTable, ...}
local mouseoverGroups = {} -- {groupTable = true, ...}
local MOUSE_TICKER_INTERVAL = 0.125

local FADE_QUEUE = {}
local inCombat = InCombatLockdown()
local lastLowHealthVis = LowHealthFrame:IsVisible()
local isMissingHealth = false
local maxHealthChangeTime = 0
local healthTimer
local lastInstanceCheck = 0
local INSTANCE_THROTTLE = 1
local pendingFades = {}
local runAfterCombat = {} -- {{fn, arg1, arg2, ...}, ...}
local framesThatToggleVisibility = {} -- {frame = {threshold = 0.1, group = groupTable }, ...}
local minimapHelperFrame -- mouseover helper frame when minimap is hidden
main.helperFrames = {}

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
local GetShapeshiftFormID, UnitInVehicle, UnitCastingInfo, UnitChannelInfo, IsResting
    = GetShapeshiftFormID, UnitInVehicle, UnitCastingInfo, UnitChannelInfo, IsResting

------------------
-- Setup
------------------

function Private:OnProfileChanged()
    db = Private.db.profile
    config.SetSelectedGroup(true)
end

local function InitDB()
    local defaultProfile = {
        profile = {
            config.GetDefaultGroup(L["name_defaultGroup"])
        }
    }

    Private.db = LibStub("AceDB-3.0"):New("AutoHideUIDB", defaultProfile, true)
    db = Private.db.profile

    Private.db.RegisterCallback(Private, "OnProfileChanged", "OnProfileChanged")
    Private.db.RegisterCallback(Private, "OnProfileCopied", "OnProfileChanged")
    Private.db.RegisterCallback(Private, "OnProfileReset", "OnProfileChanged")

    config.RegisterOptions()
end

local function InitOptions()
    config.SetSelectedGroup()
    config.CreateOptionsMenu()
end

local function RegisterEventsInCondition(condition)
    for _, info in pairs(config.CONDITION_DEFINITIONS) do
        if info.name == condition then
            for _, event in pairs(info.events) do
                main.frame:RegisterEvent(event)
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
    main.frame:UnregisterAllEvents()
    for _, group in ipairs(activeGroups) do
        RegisterEventsInGroup(group)
    end
end

local function UnregisterAllEvents()
    main.frame:UnregisterAllEvents()
end

local function ResetGroupStates(states)
    for k, v in pairs(states) do
        if type(v) == "table" then
            states[k] = CopyTable(config.DEFAULT_STATES[k])
        else
            states[k] = config.DEFAULT_STATES[k]
        end
    end
end

local function ResetAllGroupStates()
    for _, group in ipairs(activeGroups) do
        ResetGroupStates(group.states)
    end
end

local function CreateMouseoverLists()
    wipe(mouseoverFrames)
    wipe(mouseoverGroups)
    for _, group in ipairs(activeGroups) do
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

local function ResetPendingFades()
    for _, fadeInfo in ipairs(pendingFades) do
        if fadeInfo and fadeInfo.timer then
            fadeInfo.timer:Cancel()
        end
    end
    wipe(pendingFades)
end

local function ResetStates()
    ResetAllGroupStates()
    ResetPendingFades()
end

local function CancelMouseoverTicker()
    if mouseoverTicker then
        mouseoverTicker:Cancel()
        mouseoverTicker = nil
    end
end

local function ClearQueues()
    ResetPendingFades()
    internal.StopFadeAnimations()
    wipe(runAfterCombat)
end

local function ResetAddon()
    internal.ResetFrames()
    ResetStates()
    wipe(framesThatToggleVisibility)
end

local function InitAddon()
    internal.InitFrames()
    ResetPendingFades()
    RegisterAllEvents()
    CreateMouseoverLists()
    internal.CreateMouseoverTicker()
    internal.UpdateAllConditions()
    internal.SetAllAlpha()
    internal.ToggleHelperFrames()
end

function main.SuspendAddon()
    UnregisterAllEvents()
    CancelMouseoverTicker()
    ClearQueues()
    internal.SetAllAlpha(1)
end

function main.ResumeAddon()
    ResetAddon()
    InitAddon()
end

function main.GetErrorTitleString()
    return "|cff80ffffAuto Hide UI: |r"
end

function main.ColorString(string, clr)
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
    for _, entry in ipairs(runAfterCombat) do
        local func = entry[1]
        if type(func) == "function" then
            func(unpack(entry, 2))
        end
    end
    wipe(runAfterCombat)
end

------------------
-- Managing Frames
------------------

local FRAME_INFO_TEMPLATE = {frames = {}, args = {}}

local function MINIMAPCLUSTER_CUSTOMGETTER(frameString)
    local frameList = {}
    local minimapFrame = internal.GetFrameObjectFromString(frameString)
    if not minimapFrame then return
        frameList
    end
    tinsert(frameList, minimapFrame)

    if not minimapHelperFrame then
        minimapHelperFrame = CreateFrame("Frame", "minimapHelperFrame", UIParent)
        minimapHelperFrame:SetAllPoints(minimapFrame)
        -- local t = minimapHelperFrame:CreateTexture()
        -- t:SetAllPoints()
        -- t:SetColorTexture(0,1,0,0.25)
        main.helperFrames[minimapHelperFrame] = {dependency = frameString}
    end
    tinsert(frameList, minimapHelperFrame)

    framesThatToggleVisibility[minimapFrame] = {threshold = 0.1}

    return frameList
end

local ADDON_FRAME_MAPPING = {
    {
        name = "Unhalted Unit Frames",
        isLoaded = function() return C_AddOns.IsAddOnLoaded("UnhaltedUnitFrames") end,
        frames = {
            PlayerFrame = {"UUF_Player"},
            TargetFrame = {"UUF_Target", "UUF_TargetTarget"},
            FocusFrame = {"UUF_Focus", "UUF_FocusTarget"},
            PetFrame = {"UUF_Pet", "UUF_PetTarget"},
        },
        args = {forceAlpha = true},
    },
    {
        name = "Dominos",
        isLoaded = function() return C_AddOns.IsAddOnLoaded("Dominos") end,
        frames = {
            MainActionBar = {"DominosFrame1", "DominosFrame2", "DominosFrame7", "DominosFrame8", "DominosFrame9", "DominosFrame10", "DominosFrame11"}, -- stealth and shapeshift bars
            MultiBarBottomLeft = {"DominosFrame6"},
            MultiBarBottomRight = {"DominosFrame5"},
            MultiBarRight = {"DominosFrame3"},
            MultiBarLeft = {"DominosFrame4"},
            MultiBar5 = {"DominosFrame12"},
            MultiBar6 = {"DominosFrame13"},
            MultiBar7 = {"DominosFrame14"},
            StanceBar = {"DominosFrameclass"},
            PetActionBar = {"DominosFramepet"},
            MicroMenu = {"DominosFramemenu"},
            BagsBar = {"DominosFramebags"},
            MainStatusTrackingBarContainer = {"DominosFrameexp"},
        },
        args = {},
    },
    {
        name = "ElvUI",
        isLoaded = function() return ElvUI and ElvUI[1] and ElvUI[1].db and ElvUI[1].DataBars and ElvUI[1].DataBars.db and ElvUI[1].DataBars.db.experience and ElvUI[1].DataBars.db.experience.enable end,
        frames = {
            MainStatusTrackingBarContainer = {"ElvUI_ExperienceBarHolder"},
        },
        args = {},
    },
    {
        name = "ElvUI",
        isLoaded = function() return ElvUI and ElvUI[1] and ElvUI[1]:GetModule("Minimap") and ElvUI[1]:GetModule("Minimap").Initialized end,
        frames = {
            MinimapCluster = {},
        },
        args = {},
        customGetter = function()
            local frameList = MINIMAPCLUSTER_CUSTOMGETTER("MinimapCluster")
            local addonButton =  internal.GetFrameObjectFromString("AddonCompartmentFrame")
            if addonButton then
                tinsert(frameList, addonButton)
            end
            return frameList
        end,
    },
    {
        name = "ElvUI",
        isLoaded = function() return ElvUI and ElvUI[1] and ElvUI[1]:GetModule("Auras") and ElvUI[1]:GetModule("Auras").Initialized end,
        frames = {
            BuffFrame = {"ElvUIPlayerBuffs"},
            DebuffFrame = {"ElvUIPlayerDebuffs"},
        },
        args = {},
    },
    {
        name = "ElvUI",
        isLoaded = function() return ElvUI and ElvUI[1] and ElvUI[1]:GetModule("UnitFrames") and ElvUI[1]:GetModule("UnitFrames").Initialized end,
        frames = {
            PlayerFrame = {"ElvUF_Player"},
            TargetFrame = {"ElvUF_Target", "ElvUF_TargetTarget"},
            FocusFrame = {"ElvUF_Focus", "ElvUF_FocusTarget"},
            PetFrame = {"ElvUF_Pet", "ElvUF_PetTarget"},
            PartyFrame = {"ElvUF_Party"},
            PlayerCastingBarFrame = {"ElvUF_Player_CastBar"},
        },
        args = {forceAlpha = true},
    },
    {
        name = "ElvUI",
        isLoaded = function() return ElvUI and ElvUI[1] and ElvUI[1]:GetModule("ActionBars") and ElvUI[1]:GetModule("ActionBars").Initialized end,
        frames = {
            MainActionBar = {"ElvUI_Bar1", "ElvUI_Bar2", "ElvUI_Bar7", "ElvUI_Bar8", "ElvUI_Bar9", "ElvUI_Bar10"}, -- stealth and shapeshift bars
            MultiBarBottomLeft = {"ElvUI_Bar6"},
            MultiBarBottomRight = {"ElvUI_Bar5"},
            MultiBarRight = {"ElvUI_Bar3"},
            MultiBarLeft = {"ElvUI_Bar4"},
            MultiBar5 = {"ElvUI_Bar13"},
            MultiBar6 = {"ElvUI_Bar14"},
            MultiBar7 = {"ElvUI_Bar15"},
            StanceBar = {"ElvUI_StanceBar"},
            PetActionBar = {"ElvUI_BarPet"},
            MicroMenu = {"ElvUI_MicroBar"},
        },
        args = {reparent = true, forceAlpha = true},
    },
    {
        name = "Details",
        isLoaded = function() return C_AddOns.IsAddOnLoaded("Details") end,
        frames = {
            DamageMeter = {},
        },
        args = {forceAlpha = true},
        customGetter = function()
            local baseNames = {"DetailsBaseFrame", "DetailsRowFrame"}
            local count = 1
            local frameList = {}

            local detailsFrame = {}
            while detailsFrame and count < 50 do
                for i = 1,2 do
                    detailsFrame = internal.GetFrameObjectFromString(baseNames[i]..count)
                    if detailsFrame then
                        tinsert(frameList, detailsFrame)
                    end
                end
                count = count + 1
            end

            return frameList
        end
    },
}

-- used for frames in the GUI's frame selector
local SPECIAL_FRAMES = {
    MainActionBar = {
        onAdded = function()
            local function ReparentVehicleButton()
                MainMenuBarVehicleLeaveButton:SetParent(UIParent)
            end
            if inCombat then
                tinsert(runAfterCombat, {ReparentVehicleButton})
            else
                ReparentVehicleButton()
            end
        end
    },
    DamageMeter = {
        customGetter = function()
            -- to add all secondary windows
            local frameList = {}
            local count = 2
            local frameString = "DamageMeterSessionWindow"..count

            local frameObject = internal.GetFrameObjectFromString(frameString)
            while frameObject do
                if #frameList < count then
                    tinsert(frameList, frameObject)
                end
                count = count + 1
                frameString = "DamageMeterSessionWindow"..count
                frameObject = internal.GetFrameObjectFromString(frameString)
            end
            return frameList
        end
    },
    MinimapCluster = {
        customGetter = MINIMAPCLUSTER_CUSTOMGETTER,
    },
}

function internal.ToggleHelperFrames()
    for frame, info in pairs(main.helperFrames) do
        local frameString = info.dependency
        if not activeStrings[frameString].args.isInUse then
            frame:Hide()
        else
            frame:Show()
        end
    end
end

function main.FetchFramesFromString(frameString)
    if not activeStrings[frameString] then
        return
    end

    return activeStrings[frameString].frames
end

function internal.GetFrameObjectFromString(frameString)
    local frameObject = _G[frameString]
    if frameObject and frameObject.SetAlpha and not frameObject:IsForbidden() then
        return frameObject
    end
end

local function WipeActiveFramesLists()
    wipe(activeStrings)
    wipe(activeGroups)
    wipe(activeFrames)
end

local function GetFramesByArg(arg, val, includeDefault)
    local frameList = {}
    for _, frameInfo in pairs(activeStrings) do
        local isInUse = frameInfo.args.isInUse
        local isValidFrame = includeDefault or not frameInfo.args.isDefault
        if isInUse and isValidFrame and frameInfo.args[arg] == val then
            for _, frame in pairs(frameInfo.frames) do
                frameList[frame] = frameInfo
            end
        end
    end
    return frameList
end

local function RestoreOriginalAlphaFunctions()
    local arg, val = "forceAlpha", true
    local frameList = GetFramesByArg(arg, val)
    for frame in pairs(frameList) do
        if frame._origSetAlpha then
            frame.SetAlpha = frame._origSetAlpha
            frame._origSetAlpha = nil
        end

        if frame._origSetAlphaFromBoolean then
            frame.SetAlphaFromBoolean = frame._origSetAlphaFromBoolean
            frame._origSetAlphaFromBoolean = nil
        end

    end
end

local function ReplaceAlphaFunctions(frame, groupInfo)
    if frame._origSetAlpha or frame._origSetAlphaFromBoolean then
        -- we should never get here but checking anyway cause continuing would be very bad
        return
    end

    frame._origSetAlpha = frame.SetAlpha
    frame.SetAlpha = function(self, alpha) end

    if frame.SetAlphaFromBoolean then
        frame._origSetAlphaFromBoolean = frame.SetAlphaFromBoolean
        frame.SetAlphaFromBoolean = function(self)
            if internal.IsFadeInProgress(groupInfo.states) then
                return
            else
                self:_origSetAlpha(groupInfo.states.endAlpha)
            end
        end
    end

    frame.lastAlpha = frame:GetAlpha()
end

local function RestoreOriginalParents()
    if inCombat then
        tinsert(runAfterCombat, {RestoreOriginalParents})
        return
    end

    local arg, val = "reparent", true
    local frameList = GetFramesByArg(arg, val)
    for frame in pairs(frameList) do
        if frame._origParent then
            frame:SetParent(frame._origParent)
            frame._origParent = nil
        end
    end
end

local function ReparentFrame(frame)
    if frame._origParent then
        return
    end

    local origParent = frame:GetParent()
    if not origParent then
        return
    end

    frame._origParent = origParent
    frame:SetParent(UIParent)
end

local function ReparentAllCustomFrames()
    if inCombat then
        tinsert(runAfterCombat, {ReparentAllCustomFrames})
        return
    end

    local arg, val = "reparent", true
    local frameList = GetFramesByArg(arg, val)
    for frame in pairs(frameList) do
        ReparentFrame(frame)
    end
end

local function ReplaceAllAlphaFunctions()
    local arg, val = "forceAlpha", true
    local frameList = GetFramesByArg(arg, val)
    for frame, frameInfo in pairs(frameList) do
        ReplaceAlphaFunctions(frame, frameInfo.group)
    end
end

function internal.ResetFrames()
    RestoreOriginalAlphaFunctions()
    RestoreOriginalParents()
    WipeActiveFramesLists()
end

local function CreateFrameGroup(groupDB)
    local groupInfo = {
        name = groupDB.name,
        frames = {},
        config = CopyTable(groupDB.config),
        states = CopyTable(config.DEFAULT_STATES),
        conditions = CopyTable(groupDB.conditions),
    }
    return groupInfo
end

local function CreateFrameInfo(frameList, args)
    local frameInfo = CopyTable(FRAME_INFO_TEMPLATE)
    frameInfo.frames = frameList
    if args then
        frameInfo.args = args
    end
    return frameInfo
end

local function GetAddOnFrames(frameStringList)
    if not frameStringList then
        return
    end

    local frameList = {}
    -- specifically checking if first frame was found because that's the main one.
    -- no point in returning TargetOfTarget if Target couldn't be found.
    local firstFrameFound
    for index, frameString in ipairs(frameStringList) do
        local frame = internal.GetFrameObjectFromString(frameString)
        if frame then
            tinsert(frameList, frame)
            firstFrameFound = firstFrameFound or index == 1
        end
    end

    if firstFrameFound and frameList then
        return frameList
    end
end

local function CheckForAddOnStrings(frameString, addonInfo)
    -- if user enters the name of an AddOn frame instead of ticking the common frame.
    -- useful for ElvUI users who don't like that Bar1 hides other bars as well.
    -- still need to detect it this way to catch any custom args etc.
    local frameObject, args
    for _, frameStringList in pairs(addonInfo.frames) do
        for _, string in pairs(frameStringList) do
            if string == frameString then
                frameObject = internal.GetFrameObjectFromString(frameString)
                break
            end
        end
    end

    if not frameObject then
        return false
    end

    args = CopyTable(addonInfo.args)

    return {frameObject}, args
end

local function CheckForAddOnFrames(frameString, groupDB)
    for _, addonInfo in ipairs(ADDON_FRAME_MAPPING) do
        if addonInfo:isLoaded() then
            local frameList, args

            frameList, args = CheckForAddOnStrings(frameString, addonInfo)
            if frameList then
                local frameInfo = CreateFrameInfo(frameList, args)
                return frameInfo
            end

            if addonInfo.customGetter and addonInfo.frames[frameString] then
                frameList = addonInfo.customGetter(frameString)
                args = CopyTable(addonInfo.args)
            else
                frameList = GetAddOnFrames(addonInfo.frames[frameString])
                args = CopyTable(addonInfo.args)
            end

            if frameList then
                local frameInfo = CreateFrameInfo(frameList, args)
                frameInfo.args.forceAlpha = frameInfo.args.forceAlpha and groupDB.config.forceAlpha
                return frameInfo
            end

        end
    end
end

local function IsDefaultFrame(frameString)
    for _, info in ipairs(config.DEFAULT_FRAMES) do
        if frameString == info.frame then
            return true
        end
    end
    return false
end

local function HandleSpecialFrame(frameString, specialFrame)
    local frameList, args

    if specialFrame.customGetter then
        frameList, args = specialFrame.customGetter(frameString)
    else
        local frameObject = internal.GetFrameObjectFromString(frameString)
        if not frameObject then
            return
        else
            frameList = {frameObject}
        end
    end

    if not frameList then
        return
    end

    if specialFrame.onAdded then
        specialFrame.onAdded()
    end

    local frameInfo = CreateFrameInfo(frameList, args)

    return frameInfo
end

local function GetAllFrameObjectsFromString(frameString, groupDB)
    local addonFrameInfo = CheckForAddOnFrames(frameString, groupDB)
    if addonFrameInfo then
        return addonFrameInfo
    end

    local specialFrame = SPECIAL_FRAMES[frameString]
    if specialFrame then
        local frameInfo = HandleSpecialFrame(frameString, specialFrame)
        if frameInfo then
            frameInfo.args.isDefault = IsDefaultFrame(frameString)
            return frameInfo
        end
    end

    local frameObject = internal.GetFrameObjectFromString(frameString)
    if not frameObject then
        return
    end

    local frameList = {frameObject}
    local frameInfo = CreateFrameInfo(frameList)
    frameInfo.args.isDefault = IsDefaultFrame(frameString)

    return frameInfo
end

local function GetAllCommonFrames(groupDB)
    -- the GUI's frame selection
    local frameList = {}
    for frameString, isChecked in pairs(groupDB.frames) do
        local frameInfo = GetAllFrameObjectsFromString(frameString, groupDB)
        if frameInfo then
            frameList[frameString] = frameInfo
            frameInfo.args.isInUse = isChecked
        end
    end

    return frameList
end

local function GetAllCustomFrames(groupDB)
    local frameList = {}
    local frameStringList = string.gmatch(groupDB.config.customFrames, "[^,]+")
    for frameString in frameStringList do
        frameString = frameString:gsub("%s", "")
        if frameString ~= "" then
            local frameInfo = GetAllFrameObjectsFromString(frameString, groupDB)
            if frameInfo then
                frameInfo.args.forceAlpha = groupDB.config.forceAlpha
                frameInfo.args.isInUse = true
                frameList[frameString] = frameInfo
            end
        end
    end

    return frameList
end

local function CreateActiveFramesList()
    for frameString, info in pairs(activeStrings) do
        local isInUse = info.args.isInUse
        for _, frame in pairs(info.frames) do
            if not activeFrames[frame] or not activeFrames[frame].isInUse then
                activeFrames[frame] = {
                    frameString = frameString,
                    group = info.group,
                    isInUse = isInUse
                }
            end
        end
    end
end

local function FinishVisibilityFrames()
    for frame, frameInfo in pairs(framesThatToggleVisibility) do
        frameInfo.group = activeFrames[frame].group
        frameInfo.isInUse = activeFrames[frame].isInUse
    end
end

local function CombineFrameLists(frameString, frameInfo, framesInUse, indexedFrames, groupInfo)
    if not frameInfo.frames then
        return
    end

    -- reject if ANY frame is already used.
    for _, frame in ipairs(frameInfo.frames) do
        if framesInUse[frame] then
            return
        end
    end

    for _, frame in ipairs(frameInfo.frames) do
        if frameInfo.args.isInUse then
            framesInUse[frame] = true
            tinsert(indexedFrames, frame)
        end
    end

    -- without this check, having multiple groups could flag used frames as not in use
    if (not activeStrings[frameString]) or (not activeStrings[frameString].args.isInUse) then
        frameInfo.group = groupInfo
        activeStrings[frameString] = frameInfo
    end
end

local function HasFrames(frameList)
    if not frameList then
        return false
    end

    for _, frameInfo in pairs(frameList) do
        for _, frame in pairs(frameInfo.frames) do
            if frame and frameInfo.args.isInUse then
                return true
            end
        end
    end

    return false
end

local function HandleAllGroupFrames(dbIndex, groupDB)
    local commonFrames = GetAllCommonFrames(groupDB)
    local customFrames = GetAllCustomFrames(groupDB)

    if not HasFrames(commonFrames) and not HasFrames(customFrames) then
        return
    end

    activeGroups[dbIndex] = CreateFrameGroup(groupDB)

    -- helper tables to assemble final tables
    local framesInUse = {}
    local indexedFrames = {}

    -- order matters! prefer commonFrames 
    for _, source in ipairs({ commonFrames, customFrames }) do
        for frameString, frameInfo in pairs(source) do
            CombineFrameLists(frameString, frameInfo, framesInUse, indexedFrames, activeGroups[dbIndex])
        end
    end

    if not next(framesInUse) then
        return
    end

    activeGroups[dbIndex].frames = indexedFrames
end

function internal.InitFrames()
    WipeActiveFramesLists()

    for dbIndex, groupDB in ipairs(db) do
        HandleAllGroupFrames(dbIndex, groupDB)
    end

    CreateActiveFramesList()
    FinishVisibilityFrames()
    ReparentAllCustomFrames()
    ReplaceAllAlphaFunctions()
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
    for i, group in ipairs(activeGroups) do
        UpdateActiveConditions(group, condition, value)
    end
end

local function ConditionCombat()
    UpdateConditionForAllGroups("combat", inCombat)
end

local function ConditionTarget()
    local hasHostileTarget, hasFriendlyTarget

    if UnitExists("target") then
        if UnitCanAttack("player", "target") then
            hasHostileTarget = true
        else
            hasFriendlyTarget = true
        end
    end

    UpdateConditionForAllGroups("targetHostile", hasHostileTarget)
    UpdateConditionForAllGroups("targetFriendly", hasFriendlyTarget)
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

local function ConditionMounted()
    UpdateConditionForAllGroups("mounted", IsMounted())
end

local function ConditionShapeshift()
    local shapeId = GetShapeshiftFormID()
    for _, group in ipairs(activeGroups) do
        local formsKey = group.conditions.mounted.druidForms
        local validShapes = DRUID_FORMS[formsKey]
        local isMountShape = validShapes[shapeId]
        UpdateActiveConditions(group, "mounted", isMountShape)
    end
end

local function ConditionHealth()
    for _, group in ipairs(activeGroups) do
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

    healthTimer = C_Timer.NewTimer(3, function()
        isMissingHealth = false
        ConditionHealth()
        internal.FadeAllGroups()
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
    ConditionTarget()
    ConditionInstance()
    ConditionMounted()
    ConditionShapeshift()
    ConditionMouseover()
    ConditionVehicle()
    ConditionCasting()
    ConditionResting()
    ConditionHealth()
end

------------------
-- Alpha Stuff
------------------

local function PickPreferredAlpha(a1, a2, mode)
    local maxMin = mode == 1 and max or min
    return a1 and maxMin(a1, a2) or a2
end

local function GetCurrentAlpha(group)
    -- getting current alpha value so fades can reverse smoothly if necessary.
    -- checking alpha of two frames and picking the lower one, in case a random frame was stuck or reset.
    local alphaFrame
    local idleAlpha = group.config.idleAlpha

    for _, frame in pairs(group.frames) do
        if frame:IsVisible() then
            if alphaFrame then
                return min(alphaFrame, frame:GetAlpha())
            end
            alphaFrame = frame:GetAlpha()
        end
    end

    group.states.lastAlpha = group.states.lastAlpha or alphaFrame or idleAlpha
    return alphaFrame or idleAlpha
end

local function GetTargetAlpha(group)
    local alpha
    local activeConditions = group.states.activeConditions

    for _, cAlpha in pairs(activeConditions.priority) do
        if cAlpha then
            alpha = PickPreferredAlpha(alpha, cAlpha, group.config.prioAlphaPref)
        end
    end

    if alpha then
        group.states.priorityFade = true
        return alpha
    else
        group.states.priorityFade = false
    end

    for i, cAlpha in pairs(activeConditions.normal) do
        if cAlpha then
            alpha = PickPreferredAlpha(alpha, cAlpha, group.config.normalAlphaPref)
        end
    end

    return alpha or group.config.idleAlpha
end

function internal.SetAllAlpha(targetAlpha)
    for _, group in ipairs(activeGroups) do
        local newAlpha = targetAlpha or GetTargetAlpha(group)
        group.states.endAlpha = newAlpha
        for _, frame in pairs(group.frames) do
            if frame._origSetAlpha then
                frame:_origSetAlpha(newAlpha)
            else
                frame:SetAlpha(newAlpha)
            end
        end
    end
    internal.UpdateAllFrameVisibility()
end

------------------
-- Fade Stuff
------------------

-- slightly trimmed version of Blizzard's code. we also use SetAlpha differently
function AutoHide_FrameFade_OnUpdate(self, elapsed)
	local index = 1;
	local frame, fadeInfo;
	while FADE_QUEUE[index] do
		frame = FADE_QUEUE[index];
		fadeInfo = FADE_QUEUE[index].fadeInfo;
		-- Reset the timer if there isn't one, this is just an internal counter
		if ( not fadeInfo.fadeTimer ) then
			fadeInfo.fadeTimer = 0;
		end
		fadeInfo.fadeTimer = fadeInfo.fadeTimer + elapsed;

		-- If the fadeTimer is less then the desired fade time then set the alpha otherwise hold the fade state, call the finished function, or just finish the fade
		if ( fadeInfo.fadeTimer < fadeInfo.timeToFade ) then
			if ( fadeInfo.mode == "IN" ) then
				fadeInfo.fadeMethod(frame, (fadeInfo.fadeTimer / fadeInfo.timeToFade) * (fadeInfo.endAlpha - fadeInfo.startAlpha) + fadeInfo.startAlpha);
			elseif ( fadeInfo.mode == "OUT" ) then
				fadeInfo.fadeMethod(frame, ((fadeInfo.timeToFade - fadeInfo.fadeTimer) / fadeInfo.timeToFade) * (fadeInfo.startAlpha - fadeInfo.endAlpha)  + fadeInfo.endAlpha);
			end
		else
			fadeInfo.fadeMethod(frame, fadeInfo.endAlpha)
            -- Complete the fade and call the finished function if there is one
            tDeleteItem(FADE_QUEUE, frame)
            if ( fadeInfo.finishedFunc ) then
                fadeInfo.finishedFunc(fadeInfo.finishedArg1, fadeInfo.finishedArg2, fadeInfo.finishedArg3, fadeInfo.finishedArg4);
                fadeInfo.finishedFunc = nil;
            end
		end

		index = index + 1;
	end

	if ( #FADE_QUEUE == 0 ) then
		self:SetScript("OnUpdate", nil);
	end
end

function internal.StopFadeAnimations()
    wipe(FADE_QUEUE)
end

function internal.SetVisibilityFromAlpha(frame, endAlpha, threshold)
    if inCombat and frame:IsProtected() then
        return
    end

    if endAlpha > threshold then
        frame:Show()
    else
        frame:Hide()
    end
end

local function UpdateFrameVisibility(frame, frameInfo)
    if (inCombat and frame:IsProtected()) or not frameInfo then
        return
    end

    local isShown = frame:IsShown()

    if frameInfo.group.states.endAlpha >= frameInfo.threshold and not isShown then
        frame:Show()
    elseif frameInfo.group.states.endAlpha < frameInfo.threshold and isShown then
        frame:Hide()
    end
end

function internal.UpdateAllFrameVisibility(setVisibilityToValue)
    for frame, frameInfo in pairs(framesThatToggleVisibility) do
        if frameInfo.isInUse then
            if setVisibilityToValue == nil or not frame:IsProtected() then
                UpdateFrameVisibility(frame, frameInfo)
            elseif setVisibilityToValue then
                frame:Show()
            else
                frame:Hide()
            end
        end
    end
end

local function HandleVisibilityForFade(frame, fadeInfo)
    if not framesThatToggleVisibility[frame] then
        return
    end
    if fadeInfo.mode == "OUT" then
        fadeInfo.finishedFunc = UpdateFrameVisibility
        fadeInfo.finishedArg1 = frame
        fadeInfo.finishedArg2 = framesThatToggleVisibility[frame]
    else
        UpdateFrameVisibility(frame, framesThatToggleVisibility[frame])
    end
end

function internal.IsFadeInProgress(states)
    return GetTime() < states.fadeEndTime
end

local function CancelPendingFade(group)
    if pendingFades[group] and pendingFades[group].timer then
        pendingFades[group].timer:Cancel()
        pendingFades[group] = nil
    end
end

local function ApplyFade(group, targetAlpha)
    CancelPendingFade(group)

    local states = group.states

    if internal.IsFadeInProgress(states) then
        states.startAlpha = GetCurrentAlpha(group)
    else
        states.startAlpha = states.endAlpha
    end

    states.endAlpha = targetAlpha
    states.fadeEndTime = GetTime() + group.config.timeToFade

    for _, frame in pairs(group.frames) do
        tDeleteItem(FADE_QUEUE, frame) -- for safety if timeToFade is set to 0 and fades trigger within one frame
        frame.fadeInfo = {
            mode = group.states.fadeMode,
            timeToFade = group.config.timeToFade,
            startAlpha = group.states.startAlpha,
            endAlpha = group.states.endAlpha,
            fadeMethod = frame._origSetAlpha or frame.SetAlpha
        }
        HandleVisibilityForFade(frame, frame.fadeInfo)
        tinsert(FADE_QUEUE, frame)
    end

    main.frame:SetScript("OnUpdate", AutoHide_FrameFade_OnUpdate)
end

local function ScheduleFade(group, targetAlpha, delay, fadeMode)
    local pendingFade = pendingFades[group]
    if pendingFade and pendingFade.fadeMode ~= fadeMode then
        CancelPendingFade(group)
    elseif pendingFade then
        pendingFade.targetAlpha = targetAlpha
        return
    end

    local timer = C_Timer.NewTimer(delay, function()
        local fadeInfo = pendingFades[group]
        if not fadeInfo then
            return
        end

        local currentTarget = GetTargetAlpha(group)
        if currentTarget == fadeInfo.targetAlpha then
            ApplyFade(group, currentTarget)
        end

        pendingFades[group] = nil
    end)

    pendingFades[group] = {
        timer = timer,
        fadeMode = fadeMode,
        targetAlpha = targetAlpha,
    }
end

local function ShouldDelayFade(group)
    if group.states.fadeMode == "IN" and group.config.fadeInDelay > 0 then
        return true, group.config.fadeInDelay
    elseif group.states.fadeMode == "OUT" and group.config.fadeOutDelay > 0 then
        return true, group.config.fadeOutDelay
    else
        return false, 0
    end
end

local function FadeGroup(group)
    local targetAlpha = GetTargetAlpha(group)

    if targetAlpha == group.states.endAlpha then
        CancelPendingFade(group)
        return
    end

    local fadeMode = targetAlpha > group.states.endAlpha and "IN" or "OUT"
    group.states.fadeMode = fadeMode

    local shouldDelayFade, delay = ShouldDelayFade(group)
    if shouldDelayFade then
        ScheduleFade(group, targetAlpha, delay, fadeMode)
    else
        ApplyFade(group, targetAlpha)
    end
end

function internal.FadeAllGroups()
    for _, group in ipairs(activeGroups) do
        FadeGroup(group)
    end
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

local function OnTargetChanged()
    ConditionTarget()
    internal.FadeAllGroups()
end

local function OnCombatChange(combatStatus)
    inCombat = combatStatus

    -- we are running this here as well, because it's not guaranteed that both frames fire events in the order we want.
    if inCombat then
        wipe(runAfterCombat)
    else
        RunAfterCombatQueue()
    end

    ConditionCombat()
    internal.FadeAllGroups()
end

local function OnCombatStart()
    wipe(runAfterCombat)
    local setVisibilityToValue = true
    internal.UpdateAllFrameVisibility(setVisibilityToValue)
    inCombat = true
end

local function OnCombatEnd()
    inCombat = false
    internal.UpdateAllFrameVisibility()
    RunAfterCombatQueue()
end

local function OnMouseover()
    local mouseoverChanged, group = ConditionMouseover()
    if mouseoverChanged then
        FadeGroup(group)
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
    internal.SetAllAlpha()
    lastInstanceCheck = currentTime
end

local function OnMountChange()
    ConditionMounted()
    internal.FadeAllGroups()
end

local function OnShapeshift()
    ConditionShapeshift()
    internal.FadeAllGroups()
end

local function OnVehicleChange()
    ConditionVehicle()
    internal.FadeAllGroups()
end

local function OnHealthChange(unit)
    if unit ~= "player" then
        return
    end

    local lowHealthChanged = CheckLowHealthChange()
    local missingHealthChanged = CheckMissingHealthChange()

    if lowHealthChanged or missingHealthChanged then
        ConditionHealth()
        internal.FadeAllGroups()
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
    internal.FadeAllGroups()
end

local function OnCastEnd(unit)
    if unit ~= "player" then
        return
    end

    ConditionCasting(false)
    internal.FadeAllGroups()
end

local function OnRestingChange()
    ConditionResting()
    internal.FadeAllGroups()
end

------------------
-- Event Handler
------------------

local EVENT_HANDLER = {
    PLAYER_TARGET_CHANGED = OnTargetChanged,
    PLAYER_REGEN_DISABLED = function() OnCombatChange(true) end,
    PLAYER_REGEN_ENABLED = function() OnCombatChange(false) end,
    PLAYER_ENTERING_WORLD = OnInstanceChange,
    LOADING_SCREEN_DISABLED = OnInstanceChange,
    ZONE_CHANGED_NEW_AREA = OnInstanceChange,
    WORLD_CURSOR_TOOLTIP_UPDATE = OnMouseover,
    UPDATE_MOUSEOVER_UNIT = OnMouseover,
    PLAYER_MOUNT_DISPLAY_CHANGED = OnMountChange,
    UPDATE_SHAPESHIFT_FORM = OnShapeshift,
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

function main.frame:OnEvent(event, ...)
    EVENT_HANDLER[event](...)
end



main.frame:SetScript("OnEvent", main.frame.OnEvent)
systemFrame:SetScript("OnEvent", systemFrame.OnEvent)
