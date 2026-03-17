local _, Private = ...
local Main = Private.Main
local Config = Private.Config
local Frames = Private.Frames


local minimapHelperFrame -- mouseover helper frame when minimap is hidden
local FRAME_INFO_TEMPLATE = {frames = {}, args = {}}

local function MINIMAPCLUSTER_CUSTOMGETTER(frameString)
    local frameList = {}
    local minimapFrame = Frames.GetFrameObjectFromString(frameString)
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
        Main.helperFrames[minimapHelperFrame] = {frameString = frameString}
    end
    tinsert(frameList, minimapHelperFrame)

    Main.framesThatToggleVisibility[minimapFrame] = {threshold = 0.1}

    return frameList
end

local function BARTENDER_CUSTOMGETTER(frameString)
    local MAPPING = {
        MainActionBar = {
            bar = {"BT4Bar1", "BT4Bar2", "BT4Bar7", "BT4Bar8", "BT4Bar9", "BT4Bar10"},
            firstButton = {"BT4Button1","BT4Button13", "BT4Button73", "BT4Button85", "BT4Button97", "BT4Button109"}
        },
        MultiBarBottomLeft = {
            bar = {"BT4Bar6"},
            firstButton = {"BT4Button61"}
        },
        MultiBarBottomRight = {
            bar = {"BT4Bar5"},
            firstButton = {"BT4Button49"}
        },
        MultiBarRight = {
            bar = {"BT4Bar3"},
            firstButton = {"BT4Button25"}
        },
        MultiBarLeft = {
            bar = {"BT4Bar4"},
            firstButton = {"BT4Button37"}
        },
        MultiBar5 = {
            bar = {"BT4Bar13"},
            firstButton = {"BT4Button145"}
        },
        MultiBar6 = {
            bar = {"BT4Bar14"},
            firstButton = {"BT4Button157"}
        },
        MultiBar7 = {
            bar = {"BT4Bar15"},
            firstButton = {"BT4Button169"}
        },
        PetActionBar = {
            bar = {"BT4BarPetBar"},
            firstButton = {"BT4PetButton1"},
        },
        MicroMenu = {
            bar = {"BT4BarMicroMenu"},
            firstButton = {"CharacterMicroButton"},
        },
        BagsBar = {
            bar = {"BT4BarBagBar"},
            firstButton = {"CharacterReagentBag0Slot"},
        },
        -- /dump BT4Button79:GetParent():GetName()
    }
            
    local frameList = {}

    if frameString == "MainActionBar" then
        local artBar = Frames.GetFrameObjectFromString("BT4BarBlizzardArt")
        if artBar then
            tinsert(frameList, artBar)
        end
    end

    local function HandleBar(barString, buttonString)
        local barFrame = Frames.GetFrameObjectFromString(barString)
        local buttonFrame = Frames.GetFrameObjectFromString(buttonString)
        if not barFrame or not buttonFrame then
            return
        end

        local helper
        for frame, info in pairs(Main.helperFrames) do
            if info.frameString and info.frameString == barString then
                helper = frame
                break
            end
        end

        if not helper then
            helper = CreateFrame("Frame", nil, buttonFrame)
            helper:SetPoint("LEFT")
            helper:SetSize(barFrame:GetSize())
            Main.helperFrames[helper] = {
                frameString = frameString,
                isAnchor = true,
            }
            helper:Show()
        end

        tinsert(frameList, barFrame)
        tinsert(frameList, helper)

    end

    for i, barString in ipairs(MAPPING[frameString].bar) do
        local buttonString = MAPPING[frameString].firstButton[i]
        HandleBar(barString, buttonString)
    end

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
        name = "Bartender",
        isLoaded = function() return C_AddOns.IsAddOnLoaded("Bartender4") end,
        frames = {
            MainActionBar = {},
            MultiBarBottomLeft = {},
            MultiBarBottomRight = {},
            MultiBarRight = {},
            MultiBarLeft = {},
            MultiBar5 = {},
            MultiBar6 = {},
            MultiBar7 = {},
            -- StanceBar = {"DominosFrameclass"},
            PetActionBar = {},
            MicroMenu = {},
            BagsBar = {},
            -- MainStatusTrackingBarContainer = {"DominosFrameexp"},
        },
        customGetter = function(frameString) return BARTENDER_CUSTOMGETTER(frameString) end,
        args = {forceAlpha = true},
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
            local addonButton =  Frames.GetFrameObjectFromString("AddonCompartmentFrame")
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
                    detailsFrame = Frames.GetFrameObjectFromString(baseNames[i]..count)
                    if detailsFrame then
                        tinsert(frameList, detailsFrame)
                    end
                end
                count = count + 1
            end

            return frameList
        end
    },
    {
        name = "EllesmereUI",
        isLoaded = function() return C_AddOns.IsAddOnLoaded("EllesmereUIActionBars") end,
        frames = {
            MainActionBar = {"EABBar_MainBar"},
            MultiBarBottomLeft = {"EABBar_Bar2"},
            MultiBarBottomRight = {"EABBar_Bar3"},
            MultiBarRight = {"EABBar_Bar4"},
            MultiBarLeft = {"EABBar_Bar5"},
            MultiBar5 = {"EABBar_Bar6"},
            MultiBar6 = {"EABBar_Bar7"},
            MultiBar7 = {"EABBar_Bar8"},
            StanceBar = {"EABBar_StanceBar"},
            PetActionBar = {"EABBar_PetBar"},
            MicroMenu = {"EllesmereEAB_MicroBar"},
            BagsBar = {"EllesmereEAB_BagBar"},
            MainStatusTrackingBarContainer = {"EllesmereEAB_XPBar"},

        },
        args = {forceAlpha = true},
    },
    {
        name = "EllesmereUI",
        isLoaded = function() return C_AddOns.IsAddOnLoaded("EllesmereUIUnitFrames") end,
        frames = {
            PlayerFrame = {"EllesmereUIUnitFrames_Player", "ERB_PrimaryBar", "ERB_SecondaryFrame"},
            TargetFrame = {"EllesmereUIUnitFrames_Target", "EllesmereUIUnitFrames_TargetTarget"},
            FocusFrame = {"EllesmereUIUnitFrames_Focus", "EllesmereUIUnitFrames_FocusTarget"},
            PetFrame = {"EllesmereUIUnitFrames_Pet"},
        },
        args = {forceAlpha = true},
    },
    {
        name = "EllesmereUI",
        isLoaded = function() return C_AddOns.IsAddOnLoaded("EllesmereUICooldownManager") end,
        frames = {
            EssentialCooldownViewer = {"ECME_CDMBar_cooldowns"},
            UtilityCooldownViewer = {"ECME_CDMBar_utility"},
            BuffIconCooldownViewer = {"ECME_CDMBar_buffs"},
            BuffBarCooldownViewer = {"ECME_CDMBar_buffs"},
        },
        args = {forceAlpha = true},
    },
    {
        name = "EllesmereUI",
        isLoaded = function() return C_AddOns.IsAddOnLoaded("EllesmereUIResourceBars") end,
        frames = {
            PlayerCastingBarFrame = {"ERB_CastBar"},
        },
        args = {forceAlpha = true},
    },
}

-- used for frames in the GUI's frame selector
local SPECIAL_FRAMES = {
    MainActionBar = {
        onAdded = function()
            local function ReparentVehicleButton()
                MainMenuBarVehicleLeaveButton:SetParent(UIParent)
            end
            if Main.inCombat then
                tinsert(Main.runAfterCombat, {ReparentVehicleButton})
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

            local frameObject = Frames.GetFrameObjectFromString(frameString)
            while frameObject do
                if #frameList < count then
                    tinsert(frameList, frameObject)
                end
                count = count + 1
                frameString = "DamageMeterSessionWindow"..count
                frameObject = Frames.GetFrameObjectFromString(frameString)
            end
            return frameList
        end
    },
    MinimapCluster = {
        customGetter = MINIMAPCLUSTER_CUSTOMGETTER,
    },
}

function Frames.ToggleHelperFrames()
    for frame, info in pairs(Main.helperFrames) do
        local frameString = info.frameString
        if Main.activeStrings[frameString] then
            if not Main.activeStrings[frameString].args.isInUse then
                frame:Hide()
            else
                frame:Show()
            end
        else
            frame:Hide()
        end
    end
end

function Main.FetchFramesFromString(frameString)
    if not Main.activeStrings[frameString] then
        return
    end

    return Main.activeStrings[frameString].frames
end

function Frames.GetFrameObjectFromString(frameString)
    local frameObject = _G[frameString]
    if frameObject and frameObject.SetAlpha and not frameObject:IsForbidden() then
        return frameObject
    end
end

local function WipeActiveFramesLists()
    wipe(Main.activeStrings)
    wipe(Main.activeGroups)
    wipe(Main.activeFrames)
end

local function GetFramesByArg(arg, val, includeDefault)
    local frameList = {}
    for _, frameInfo in pairs(Main.activeStrings) do
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
            if Private.Fading.IsFadeInProgress(groupInfo.states) then
                return
            else
                self:_origSetAlpha(groupInfo.states.endAlpha)
            end
        end
    end

    frame.lastAlpha = frame:GetAlpha()
end

local function RestoreOriginalParents()
    if Main.inCombat then
        tinsert(Main.runAfterCombat, {RestoreOriginalParents})
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
    if Main.inCombat then
        tinsert(Main.runAfterCombat, {ReparentAllCustomFrames})
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

function Frames.ResetFrames()
    RestoreOriginalAlphaFunctions()
    RestoreOriginalParents()
    WipeActiveFramesLists()
end

local function CreateFrameGroup(groupDB, dbIndex)
    local groupInfo = {
        name = groupDB.name,
        frames = {},
        index = dbIndex,
        config = CopyTable(groupDB.config),
        states = CopyTable(Config.DEFAULT_STATES),
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
    -- specifically checking if first frame was found because that's the Main one.
    -- no point in returning TargetOfTarget if Target couldn't be found.
    local firstFrameFound
    for index, frameString in ipairs(frameStringList) do
        local frame = Frames.GetFrameObjectFromString(frameString)
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
                frameObject = Frames.GetFrameObjectFromString(frameString)
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
    for addonName, addonInfo in ipairs(ADDON_FRAME_MAPPING) do
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
    for _, info in ipairs(Config.DEFAULT_FRAMES) do
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
        local frameObject = Frames.GetFrameObjectFromString(frameString)
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

    local frameObject = Frames.GetFrameObjectFromString(frameString)
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
            frameInfo.args.isCustom = false
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
                frameInfo.args.isCustom = true
                frameList[frameString] = frameInfo
            end
        end
    end

    return frameList
end

local function CreateActiveFramesList()
    for frameString, info in pairs(Main.activeStrings) do
        for _, frame in pairs(info.frames) do
            if not Main.activeFrames[frame] or not Main.activeFrames[frame].isInUse then
                Main.activeFrames[frame] = {
                    frameString = frameString,
                    group = info.group,
                    isInUse = info.args.isInUse,
                    isCustom = info.args.isCustom,
                    name = frame:GetName()
                }
            end
        end
    end
end

local function FinishVisibilityFrames()
    for frame, frameInfo in pairs(Main.framesThatToggleVisibility) do
        if Main.activeFrames[frame] then
            frameInfo.group = Main.activeFrames[frame].group
            frameInfo.isInUse = Main.activeFrames[frame].isInUse
        end
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
    if (not Main.activeStrings[frameString]) or (not Main.activeStrings[frameString].args.isInUse) then
        frameInfo.group = groupInfo
        Main.activeStrings[frameString] = frameInfo
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

    Main.activeGroups[dbIndex] = CreateFrameGroup(groupDB, dbIndex)

    -- helper tables to assemble final tables
    local framesInUse = {}
    local indexedFrames = {}

    -- order matters! prefer commonFrames 
    for _, source in ipairs({ commonFrames, customFrames }) do
        for frameString, frameInfo in pairs(source) do
            CombineFrameLists(frameString, frameInfo, framesInUse, indexedFrames, Main.activeGroups[dbIndex])
        end
    end

    if not next(framesInUse) then
        return
    end

    Main.activeGroups[dbIndex].frames = indexedFrames
end

function Frames.InitFrames()
    WipeActiveFramesLists()

    for dbIndex, groupDB in ipairs(Private.db.profile) do
        HandleAllGroupFrames(dbIndex, groupDB)
    end

    CreateActiveFramesList()
    FinishVisibilityFrames()
    ReparentAllCustomFrames()
    ReplaceAllAlphaFunctions()
end