local _, Private = ...
-- namespaces for functions that are called between files
local Main = Private.Main
local Config = Private.Config
-- namespace for functions that are referenced before they are defined
local internal = {}

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local pairs, ipairs  = pairs, ipairs

local isAceHooked = false
local selectedGroup
local isOptionsOpen
local MENU_WIDTH = 630
local MENU_HEIGHT = 830
local MENU_HEIGHT_MIN = 400
local MENU_HEIGHT_MAX = 1000
local UI_WIDTH, UI_HEIGHT
local UI_PADDING = 5
local CONDITION_MAXIMUM_WIDTH = 2.95
local highlightFrames = {}
local sessionOptionStates = {} -- misc option states that don't need to be stored in SV
local popupContext = {
    titleText = "",
    editBoxText = "",
    callbacks = {
        create = function(name) end,
        rename = function(name) end,
        delete = function() end,
    },
    entityID = 1,
}

------------------
-- UI Data
------------------

-- same order as these will appear in the options
Config.DEFAULT_FRAMES = {
    -- unitframes
    { frame = "PlayerFrame", label = L["Player Frame"], enabled = true },
    { frame = "TargetFrame", label = L["Target Frame"], enabled = true },
    { frame = "FocusFrame", label = L["Focus Frame"], enabled = false },
    { frame = "PetFrame", label = L["Pet Frame"], enabled = true },
    { frame = "PartyFrame", label = L["Party Frame"], enabled = false },
    { frame = "PlayerCastingBarFrame", label = L["Player Castbar"], enabled = false },
    -- actionbars
    { frame = "MainActionBar", label = L["ActionBar 1"], enabled = true, description = L["descr_ActionBar1"] },
    { frame = "MultiBarBottomLeft", label = L["ActionBar 2"], enabled = true },
    { frame = "MultiBarBottomRight", label = L["ActionBar 3"], enabled = true },
    { frame = "MultiBarRight", label = L["ActionBar 4"], enabled = true },
    { frame = "MultiBarLeft", label = L["ActionBar 5"], enabled = true },
    { frame = "MultiBar5", label = L["ActionBar 6"], enabled = true },
    { frame = "MultiBar6", label = L["ActionBar 7"], enabled = true },
    { frame = "MultiBar7", label = L["ActionBar 8"], enabled = true },
    { frame = "StanceBar", label = L["Stance Bar"], enabled = true },
    { frame = "PetActionBar", label = L["Pet Bar"], enabled = true },
    -- CDM
    { frame = "EssentialCooldownViewer", label = L["CDManager Essential"], enabled = true },
    { frame = "UtilityCooldownViewer", label = L["CDManager Utility"], enabled = true },
    { frame = "BuffIconCooldownViewer", label = L["CDManager Buffs"], enabled = true },
    { frame = "BuffBarCooldownViewer", label = L["CDManager Bars"], enabled = true },
    { frame = "BuffFrame", label = L["Buff Frame"], enabled = false },
    { frame = "DebuffFrame", label = L["Debuff Frame"], enabled = false },
    { frame = "PersonalResourceDisplayFrame", label = L["Personal Resource"], enabled = true },
    -- other
    { frame = "DamageMeter", label = L["Damage Meter"], enabled = true },
    { frame = "MinimapCluster", label = L["Minimap"], enabled = false , description = L["descr_Minimap"]},
    { frame = "MicroMenu", label = L["Micro Menu"], enabled = false },
    { frame = "ObjectiveTrackerFrame", label = L["Objectives Frame"], enabled = false },
    { frame = "MainStatusTrackingBarContainer", label = L["Experience Bar"], enabled = false },
    { frame = "BagsBar", label = L["Bags Bar"], enabled = true },

}

local function GetCommonFrames()
    local frameList = {}
    for _, frameInfo in ipairs(Config.DEFAULT_FRAMES) do
        frameList[frameInfo.frame] = frameInfo.enabled
    end
    return frameList
end

-- same order as these will appear in the options.
-- it's important to list parents before their children!
Config.CONDITION_DEFINITIONS = {
    {
        name = "combat",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
        },
        events = {
            "PLAYER_REGEN_ENABLED",
            "PLAYER_REGEN_DISABLED",
        },
        type = "default",
    },
    ----------------------
    -- START instance
    ----------------------
    {
        name = "instance",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
        },
        events = {
            "PLAYER_ENTERING_WORLD",
            "LOADING_SCREEN_DISABLED",
            "ZONE_CHANGED_NEW_AREA",
        },
        type = "parent",
    },
    {
        name = "instanceDungeon",
        db = {
            enabled = true,
            customize = false,
            alpha = 1,
            priority = false,
        },
        type = "child",
        parent = "instance",
    },
    {
        name = "instanceRaid",
        db = {
            enabled = true,
            customize = false,
            alpha = 1,
            priority = false,
        },
        type = "child",
        parent = "instance",
    },
    {
        name = "instanceBattleground",
        db = {
            enabled = true,
            customize = false,
            alpha = 1,
            priority = false,
        },
        type = "child",
        parent = "instance",
    },
    {
        name = "instanceArena",
        db = {
            enabled = true,
            customize = false,
            alpha = 1,
            priority = false,
        },
        type = "child",
        parent = "instance",
    },
    {
        name = "instanceScenario",
        db = {
            enabled = true,
            customize = false,
            alpha = 1,
            priority = false,
        },
        type = "child",
        parent = "instance",
    },
    {
        name = "instanceNeighborhood",
        db = {
            enabled = false,
            customize = true,
            alpha = 0,
            priority = true,
        },
        type = "child",
        parent = "instance",
    },
    {
        name = "instanceHousing",
        db = {
            enabled = false,
            customize = true,
            alpha = 0,
            priority = true,
        },
        type = "child",
        parent = "instance",
    },
    ----------------------
    -- END instance
    ----------------------
    {
        name = "mouseover",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
            trigger = 1,
        },
        events = {
            "WORLD_CURSOR_TOOLTIP_UPDATE",
            "UPDATE_MOUSEOVER_UNIT",
        },
        type = "default",
        extraOptions = {
            {
                entryName = "dropdown_mouseover",
                settingName = "trigger",
                widget = {
                    desc = L["descr_mouseover"],
                    type = "select",
                    width = 0.8,
                    values = function() return {L["dropdownOption_mouseover1"], L["dropdownOption_mouseover2"]} end,
                },
            },
        },
    },
    ----------------------
    -- START target
    ----------------------
    {
        name = "target",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
            softTarget = false,
        },
        events = {
            "PLAYER_TARGET_CHANGED",
            "PLAYER_SOFT_ENEMY_CHANGED",
            "PLAYER_SOFT_FRIEND_CHANGED",
        },
        type = "parent",
        extraOptions = {
            {
                entryName = "checkbox_softTarget",
                settingName = "softTarget",
                widget = {
                    desc = L["descr_softTarget"],
                    type = "toggle",
                    width = 0.8,
                },
            },
        },
    },
    {
        name = "targetFriendly",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
            softTarget = false,
        },
        type = "child",
        parent = "target",
    },
    {
        name = "targetHostile",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
            softTarget = false,
        },
        type = "child",
        parent = "target",
    },
    ----------------------
    -- END target 
    ----------------------

    ----------------------
    -- START focus 
    ----------------------
    {
        name = "focus",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
        },
        events = {
            "PLAYER_FOCUS_CHANGED",
        },
        type = "parent",
    },
    {
        name = "focusFriendly",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
        },
        type = "child",
        parent = "focus",
    },
    {
        name = "focusHostile",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
        },
        type = "child",
        parent = "focus",
    },
    ----------------------
    -- END focus
    ----------------------
    {
        name = "interactable",
        db = {
            enabled = false,
            alpha = 1,
            priority = false,
            excludeNPCs = true,
        },
        events = {
            "PLAYER_SOFT_INTERACT_CHANGED",
        },
        type = "default",
        description = L["descr_interactable"],
        extraOptions = {
            {
                entryName = "checkbox_excludeNPCs",
                settingName = "excludeNPCs",
                widget = {
                    desc = L["descr_excludeNPCs"],
                    type = "toggle",
                    width = 0.8,
                },
            },
        },
    },
    {
        name = "casting",
        db = {
            enabled = true,
            alpha = 0.5,
            priority = false,
        },
        events = {
            "UNIT_SPELLCAST_START",
            "UNIT_SPELLCAST_STOP",
            "UNIT_SPELLCAST_CHANNEL_START",
            "UNIT_SPELLCAST_CHANNEL_STOP",
        },
        type = "default",
    },
    {
        name = "resting",
        db = {
            enabled = false,
            alpha = 0,
            priority = false,
        },
        events = {
            "PLAYER_UPDATE_RESTING",
        },
        type = "default",
    },
    {
        name = "health",
        db = {
            enabled = true,
            alpha = 1,
            style = 2,
            priority = false,
        },
        events = {
            "UNIT_HEALTH",
            "UNIT_MAXHEALTH",
            "UNIT_MAX_HEALTH_MODIFIERS_CHANGED",
        },
        type = "default",
        description = L["descr_health"],
        extraOptions = {
            {
                entryName = "dropdown_health",
                settingName = "style",
                widget = {
                    desc = L["descr_health"],
                    type = "select",
                    width = 0.8,
                    values = function() return {L["dropdownOption_health1"], L["dropdownOption_health2"], L["dropdownOption_health3"], L["dropdownOption_health4"]} end,
                },
            },
        },
    },
    {
        name = "mounted",
        db = {
            enabled = false,
            alpha = 1,
            druidForms = 1,
            priority = false,
        },
        events = {
            "PLAYER_MOUNT_DISPLAY_CHANGED",
            "UPDATE_SHAPESHIFT_FORM",
        },
        type = "default",
        extraOptions = {
            {
                entryName = "dropdown_druidForms",
                settingName = "druidForms",
                widget = {
                    type = "select",
                    width = 0.8,
                    values = function() return {L["dropdownOption_druid1"], L["dropdownOption_druid2"], L["dropdownOption_druid3"]} end,
                },
            },
        },
    },
    {
        name = "flying",
        db = {
            enabled = false,
            alpha = 1,
            style = 3,
            priority = false,
        },
        events = {
            "PLAYER_MOUNT_DISPLAY_CHANGED",
            "UPDATE_SHAPESHIFT_FORM",
            "PLAYER_IS_GLIDING_CHANGED",
        },
        type = "default",
        extraOptions = {
            {
                entryName = "dropdown_flightStyle",
                settingName = "style",
                widget = {
                    type = "select",
                    width = 0.8,
                    values = function() return {L["dropdownOption_flight1"], L["dropdownOption_flight2"], L["dropdownOption_flight3"]} end,
                },
            },
        },
    },
    {
        name = "inVehicle",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
        },
        type = "default",
        events = {
            "UNIT_ENTERED_VEHICLE",
            "UNIT_EXITED_VEHICLE",
            "UPDATE_OVERRIDE_ACTIONBAR"
        },
    },

    -- remember to add new condition function to UpdateAllConditions
}

local GROUP_TEMPLATE = {
    name = "New Group",
    frames = {},
    conditions = {},
    config = {
        enabled = true,
        timeToFade = 0.15,
        fadeOutDelay = 2,
        fadeInDelay = 0,
        idleAlpha = 0,
        normalAlphaPref = 1, -- 1 = highest, 2 = lowest
        prioAlphaPref = 1,
        customFrames = "",
        forceAlpha = true,
    },
    states = {},
    mouseoverAreas = {},
}

local ALPHA_PREF = {
    L["Highest"], L["Lowest"],
}

------------------
-- UI Logic
------------------

local function IsOtherWindowsShown()
    return AutoHideUIFrameFinderFrame:IsShown() or AutoHideUIMouseoverAreasFrame:IsShown()
end

function Config.PrintOptionsOpenError()
    local title = Main.GetErrorTitleString()
    local message = Main.ColorString(L["error_optionsOpen"], "red")
    print(title..message)
end

local function GetDefaultConditions()
    local conditions = {}
    for _, condition in ipairs(Config.CONDITION_DEFINITIONS) do
        conditions[condition.name] = CopyTable(condition.db)
    end
    return conditions
end

function Config.CheckTextBounds(frame)
    if not frame.text then
        return
    end

    -- idk why but DetailsWaitFrameBG is larger than 0 when we add it, but is 0 here.
    local w,h = frame:GetSize()
    if w*h < 10 then
        return
    end

    local x, y = 0, 0

    local leftBorder = 0 + UI_PADDING
    local rightBorder = UI_WIDTH - UI_PADDING
    local topBorder = UI_HEIGHT - UI_PADDING
    local bottomBorder = 0 + UI_PADDING

    frame.text:SetPointsOffset(0, 0)
    local left = frame.text:GetLeft()
    local right = frame.text:GetRight()
    local top = frame.text:GetTop()
    local bottom = frame.text:GetBottom()

    if left < leftBorder then
        x = math.abs(leftBorder - left)
    elseif right > rightBorder then
        x = (rightBorder - right)
    end

    if top > topBorder then
        y = (topBorder - top)
    elseif bottom < bottomBorder then
        y = math.abs(bottomBorder - bottom)
    end

    frame.text:SetPointsOffset(x, y)
end

local function CreateNewHighlight()
    -- to highlight frames when user hovers over frame selection options.
    local frame = CreateFrame("Frame", nil, UIParent)
    local texture = frame:CreateTexture()
    texture:SetAllPoints()
    texture:SetColorTexture(1, 1, 1, 0.6)
    frame.texture = texture
    frame:Hide()
    frame:SetFrameStrata("HIGH")
    local text = frame:CreateFontString()
    text:SetFont(GameFontNormal:GetFont(), 35, "THICKOUTLINE")
    text:SetPoint("BOTTOM", frame, "TOP")
    frame.text = text
    local hlInfo = {frame = frame, inUse = false}
    tinsert(highlightFrames, hlInfo)

    return hlInfo
end

local function GetNextHighlight()
    for i, info in pairs(highlightFrames) do
        if info.frame and not info.inUse then
            info.inUse = true
            return info.frame
        end
    end

    local newInfo = CreateNewHighlight()
    newInfo.inUse = true
    return newInfo.frame
end

function Config.ShowHighlight(frame)
    if Main.helperFrames[frame] and not Main.helperFrames[frame].isAnchor then
        return
    end

    local highlight = GetNextHighlight()

    if frame:IsVisible() then
        highlight.texture:SetVertexColor(0, 1, 0)
    else
        highlight.texture:SetVertexColor(1, 1, 0)
    end

    highlight:SetAllPoints(frame)
    highlight.text:SetText(frame:GetName())
    Config.CheckTextBounds(highlight)
    highlight:Show()
end

function Config.HideAllHighlights()
    for i, info in pairs(highlightFrames) do
        if info.frame then
            info.frame:Hide()
            info.inUse = false
        end
    end
end

local function GetGroupNames()
    local groupNames = {}
    for _, group in ipairs(Private.db.profile.groups) do
        tinsert(groupNames, group.name)
    end
    return groupNames
end

function Config.SetSelectedGroup(profileChanged)
    -- keeping last selection
    if profileChanged then
        selectedGroup = 1
    elseif selectedGroup and Private.db.profile.groups[selectedGroup] then
        return
    end

    selectedGroup = nil
    for index in ipairs(Private.db.profile.groups) do
        selectedGroup = index
        break
    end
end

local function NoSelectedGroup()
    return not selectedGroup
end

local function RefreshUI()
    AceConfigRegistry:NotifyChange("AutoHideUI")
end

local function IsFrameSelectedElsewhere(frameString)
    for index, group in pairs(Private.db.profile.groups) do
        if index ~= selectedGroup and group.frames[frameString] then
            return true
        end
    end
    return false
end

local function DisableSelectedGroupConditions()
    for _, info in pairs(Private.db.profile.groups[selectedGroup].conditions) do
        info.enabled = false
    end
end

local function SetSelectedGroupToDefault()
    for cName, cDB in pairs(GetDefaultConditions()) do
        Private.db.profile.groups[selectedGroup].conditions[cName] = cDB
    end
end

local function ShowGroupCreateDialog()
    --StaticPopup_Hide("AUTOHIDEUI_CREATE_ENTITY")
    popupContext.titleText = L["popup_createGroup"]
    popupContext.editBoxText = L["button_newGroup"]

    popupContext.callbacks.createOnAccept = function(name)
        table.insert(Private.db.profile.groups, internal.GetNewGroup(name))
        selectedGroup = #Private.db.profile.groups
    end

    StaticPopup_Show("AUTOHIDEUI_CREATE_ENTITY")
end

local function ShowGroupRenameDialog()
    --StaticPopup_Hide("AUTOHIDEUI_RENAME_ENTITY")
    popupContext.titleText = L["popup_renameGroup"]
    popupContext.editBoxText = Private.db.profile.groups[selectedGroup].name

    popupContext.callbacks.renameOnAccept = function(name)
        Private.db.profile.groups[selectedGroup].name = name
    end

    StaticPopup_Show("AUTOHIDEUI_RENAME_ENTITY")
end

local function ShowGroupDeleteDialog()
    --StaticPopup_Hide("AUTOHIDEUI_DELETE_ENTITY")
    popupContext.titleText = L["popup_deleteGroup"]

    popupContext.callbacks.deleteOnShow = function(self)
        if selectedGroup and Private.db.profile.groups[selectedGroup] then
            self:SetText(string.format("%s|n|n-- %s --|n", L["popup_deleteGroup"], Private.db.profile.groups[selectedGroup].name))
        end
    end

    popupContext.callbacks.deleteOnAccept = function()
        if selectedGroup then
            table.remove(Private.db.profile.groups, selectedGroup)
            Config.SetSelectedGroup()
        end
    end

    StaticPopup_Show("AUTOHIDEUI_DELETE_ENTITY")
end

StaticPopupDialogs["AUTOHIDEUI_CREATE_ENTITY"] = {
    text = popupContext.titleText,
    button1 = L["button_create"],
    button2 = L["button_cancel"],
    hasEditBox = true,
    timeout = 0,
    whileDead = true,

    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
        self:GetEditBox():SetText(popupContext.editBoxText)
        self:GetEditBox():HighlightText()
    end,

    OnAccept = function(self)
        if not isOptionsOpen then
            Config.PrintOptionsOpenError()
            return
        end

        local newName = self:GetEditBox():GetText()
        if newName and newName ~= "" then
            popupContext.callbacks.createOnAccept(newName)
            RefreshUI()
        end
    end,

    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,

    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        StaticPopup_OnClick(parent, 1)
    end,
}

StaticPopupDialogs["AUTOHIDEUI_RENAME_ENTITY"] = {
    text = popupContext.titleText,
    button1 = L["button_rename"],
    button2 = L["button_cancel"],
    hasEditBox = true,
    timeout = 0,
    whileDead = true,

    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
        self:GetEditBox():SetText(popupContext.editBoxText)
        self:GetEditBox():HighlightText()
    end,

    OnAccept = function(self)
        if not isOptionsOpen then
            Config.PrintOptionsOpenError()
            return
        end

        local newName = self:GetEditBox():GetText()
        if newName and newName ~= "" then
            popupContext.callbacks.renameOnAccept(newName)
            RefreshUI()
        end
    end,

    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,

    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        StaticPopup_OnClick(parent, 1)
    end,
}

StaticPopupDialogs["AUTOHIDEUI_DELETE_ENTITY"] = {
    text = popupContext.titleText,
    button1 = L["button_delete"],
    button2 = L["button_cancel"],
    timeout = 0,
    whileDead = true,

    OnShow = function(self)
        popupContext.callbacks.deleteOnShow(self)
        self:SetFrameStrata("TOOLTIP")
    end,

    OnAccept = function(self)
        if not isOptionsOpen then
            Config.PrintOptionsOpenError()
            return
        end

        popupContext.callbacks.deleteOnAccept()
        RefreshUI()
    end,

    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
}

local function CloseAllPopups()
    -- StaticPopup_Hide("AUTOHIDEUI_CREATE_GROUP")
    -- StaticPopup_Hide("AUTOHIDEUI_RENAME_GROUP")
    -- StaticPopup_Hide("AUTOHIDEUI_DELETE_GROUP")
    StaticPopup_Hide("AUTOHIDEUI_CREATE_ENTITY")
    StaticPopup_Hide("AUTOHIDEUI_RENAME_ENTITY")
    StaticPopup_Hide("AUTOHIDEUI_DELETE_ENTITY")
    Private.Changelog.frame:SetShown(false)
end

------------------
-- UI Layout
------------------

local OPTIONS_TAB_FRAMES = {
    name = L["tab_frameSelect"],
    type = "group",
    disabled = NoSelectedGroup,
    args = {
        spacer_frames1 = {
            type = "description",
            name = "",
            fontSize = "small",
            order = 1,
        },
        group_defaultFrames = {
            name = L["group_defaultFrames"],
            type = "group",
            inline = true,
            order = 5,
            args = {}, -- filled in later
        },
        group_customFrames = {
            name = L["group_customFrames"],
            type = "group",
            inline = true,
            order = 10,
            args = {
                button_frameFinder = {
                    name = L["frameFinder"],
                    desc = L["descr_frameFinder"],
                    type = "execute",
                    width = 1,
                    func = function() Private.FrameFinder.Start(selectedGroup) end,
                    order = 1,
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    width = 0.1,
                    order = 2
                },
                button_mouseoverArea = {
                    name = L["mouseoverAreas"],
                    desc = L["descr_mouseoverAreas"],
                    type = "execute",
                    width = 1,
                    func = function() Private.MouseoverAreas.Start(selectedGroup) end,
                    order = 3,
                },
                descr_customFrames = {
                    type = "description",
                    fontSize = "medium",
                    name = L["descr_customFrames"].."|n",
                    width = "full",
                    order = 4,
                },
                editbox_customFrames = {
                    type = "input",
                    name = "",
                    width = "full",
                    get = function(info) return Private.db.profile.groups[selectedGroup].config.customFrames end,
                    set = function(info, value) Private.db.profile.groups[selectedGroup].config.customFrames = value end,
                    multiline = true,
                    order = 5,
                },
            },
        },
    },
    order = 21,
}

local OPTIONS_TAB_FADE = {
    name = L["tab_fadeSetup"],
    type = "group",
    disabled = NoSelectedGroup,
    args = {
        group_conditionList22 = {
            name = L["group_fadeAnimation"],
            type = "group",
            inline = true,
            order = 5,
            args = {
                fadeOutDelay = {
                    type = "range",
                    name = L["slider_fadeOutDelay"],
                    width = 1,
                    min = 0,
                    max = 60,
                    softMax = 10,
                    bigStep = 0.1,
                    get = function() return Private.db.profile.groups[selectedGroup].config.fadeOutDelay end,
                    set = function(_, value) Private.db.profile.groups[selectedGroup].config.fadeOutDelay = value end,
                    order = 5,
                },
                fadeInDelay = {
                    type = "range",
                    name = L["slider_fadeInDelay"],
                    width = 1,
                    min = 0,
                    max = 60,
                    softMax = 10,
                    bigStep = 0.1,
                    get = function() return Private.db.profile.groups[selectedGroup].config.fadeInDelay end,
                    set = function(_, value) Private.db.profile.groups[selectedGroup].config.fadeInDelay = value end,
                    order = 6,
                },
                fadeDuration = {
                    type = "range",
                    name = L["slider_fadeDuration"],
                    width = 1,
                    min = 0,
                    max = 5,
                    softMax = 1,
                    get = function() return Private.db.profile.groups[selectedGroup].config.timeToFade end,
                    set = function(_, value) Private.db.profile.groups[selectedGroup].config.timeToFade = value end,
                    order = 10,
                },
            },
        },
        group_alpha = {
            name = L["group_alpha"],
            type = "group",
            inline = true,
            order = 10,
            args = {
                idleAlpha = {
                    type = "range",
                    name = L["slider_idleAlpha"],
                    width = 1.5,
                    min = 0,
                    max = 1,
                    get = function() return Private.db.profile.groups[selectedGroup].config.idleAlpha end,
                    set = function(_, value) Private.db.profile.groups[selectedGroup].config.idleAlpha = value end,
                    order = 1,
                },
                checkbox_forceAlpha = {
                    type = "toggle",
                    name = L["checkbox_forceAlpha"],
                    desc = L["desc_forceAlpha"],
                    width = 1.5,
                    get = function(info) return Private.db.profile.groups[selectedGroup].config.forceAlpha end,
                    set = function(info, value) Private.db.profile.groups[selectedGroup].config.forceAlpha = value end,
                    order = 2,
                },
                descrAlphaPref = {
                    type = "description",
                    name = "|n"..L["descr_alphaPref"].."|n",
                    fontSize = "medium",
                    order = 5,
                },
                dropdownAlphaPref = {
                    name = L["dropdown_alphaPref"],
                    type = "select",
                    width = 1.3,
                    values = function() return ALPHA_PREF end,
                    get = function() return Private.db.profile.groups[selectedGroup].config.normalAlphaPref end,
                    set = function(_, value) Private.db.profile.groups[selectedGroup].config.normalAlphaPref = value end,
                    desc = L["tooltip_alphaPref"],
                    order = 6,
                },
                dropdownPrioAlphaPref = {
                    name = L["dropdown_prioAlphaPref"],
                    type = "select",
                    width = 1.3,
                    values = function() return ALPHA_PREF end,
                    get = function() return Private.db.profile.groups[selectedGroup].config.prioAlphaPref end,
                    set = function(_, value) Private.db.profile.groups[selectedGroup].config.prioAlphaPref = value end,
                    desc = L["tooltip_prioAlphaPref"],
                    order = 7,
                },
            },
        },
    },
    order = 22,
}

local OPTIONS_TAB_CONDITIONS = {
    name = L["tab_fadeConditions"],
    type = "group",
    disabled = NoSelectedGroup,
    args = {
        descrConditions = {
            type = "description",
            name = "|n"..L["descr_conditions"].."|n|n",
            fontSize = "medium",
            order = 5,
        },
        group_conditionSelect = {
            name = L["group_conditions"],
            type = "group",
            inline = true,
            order = 15,
            args = {
                buttonDisable = {
                    name = L["button_disableAll"],
                    type = "execute",
                    confirm = true,
                    width = 0.7,
                    func = DisableSelectedGroupConditions,
                    order = 1,
                },
                buttonReset = {
                    name = L["button_reset"],
                    type = "execute",
                    confirm = true,
                    width = 1,
                    func = SetSelectedGroupToDefault,
                    order = 2,
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    width = 0.5,
                    order = 3,
                },
                spacer2 = {
                    type = "description",
                    name = " ",
                    width = "full",
                    order = 4,
                }
                -- rest is filled in later
            },
        },
    },
    order = 23
}

local OPTIONS_TAB_MANUAL_CONTROL = {
    name = L["tab_manualControl"],
    type = "group",
    disabled = NoSelectedGroup,
    args = {
        descrConditions = {
            type = "description",
            name = "|n"..L["descr_manualControl"].."|n|n",
            fontSize = "medium",
            order = 5,
        },
        buttonNew = {
            name = L["button_newOverride"],
            type = "execute",
            confirm = true,
            width = 0.7,
            --func = CreateNewOverride,
            func = function() end,
            order = 10,
        },
        overrideContainer = {
            type = "group",
            name = "",
            order = 15,
            hidden = function() return #Private.db.profile.manualControl == 0 end,
            args = {}

        },

    },
    order = 5
}

local OPTIONS_MENU = {
    type = "group",
    name = "Auto Hide UI",
    childGroups = "tab",
    args = {
        setup = {
            name = L["tab_setup"],
            type = "group",
            childGroups = "tab",
            order = 1,
            args = {
                header_groups = {
                    type = "header",
                    name = function()
                        local groupName = Private.db and Private.db.profile.groups[selectedGroup].name or "?"
                        return groupName
                    end,
                    order = 1,
                },
                groupSelection = {
                    name = L["dropdown_groupSelect"],
                    type = "select",
                    values = function() return GetGroupNames() end,
                    get = function() return selectedGroup end,
                    set = function(_, value) selectedGroup = value end,
                    desc = L["descr_groups"],
                    width = 1,
                    order = 3,
                },
                buttonNew = {
                    name = L["button_newGroup"],
                    type = "execute",
                    width = 0.9,
                    func = ShowGroupCreateDialog,
                    desc = L["descr_groups"],
                    order = 5,
                },
                buttonRename = {
                    name = L["button_renameGroup"],
                    type = "execute",
                    width = 0.7,
                    func = ShowGroupRenameDialog,
                    order = 10,
                },
                buttonDelete = {
                    name = L["button_deleteGroup"],
                    type = "execute",
                    width = 0.7,
                    func = ShowGroupDeleteDialog,
                    order = 15,
                },
                tabFrames = OPTIONS_TAB_FRAMES,
                tabFade = OPTIONS_TAB_FADE,
                tabConditions = OPTIONS_TAB_CONDITIONS,
            },

        },
        --tabManualOverride = OPTIONS_TAB_MANUAL_CONTROL,
        changelogAnchor = {
            type = "description",
            dialogControl = "AutoHideUI_ChangelogButtonAnchor",
            name = "",
            order = 20,
        },
        -- profiles is set later when db has actually been initialized
    },
}

local function GetElementForFrameSelection(order, frameInfo)
    local frameString = frameInfo.frame
    local checkbox = {
        name = frameInfo.label,
        type = "toggle",
        get = function(info) return Private.db.profile.groups[selectedGroup].frames[frameString] end,
        set = function(info, value) Private.db.profile.groups[selectedGroup].frames[frameString] = value end,
        disabled = function(info)
            return IsFrameSelectedElsewhere(frameString)
        end,
        dialogControl = "AutoHideUI_ToggleHover",
        desc = frameInfo.description, -- most times is nil
        order = order,
        arg = {frameString = frameString},
    }

    return frameInfo.frame, checkbox
end

local function SetupFrameSelection()
    local path = OPTIONS_MENU.args.setup.args.tabFrames.args.group_defaultFrames.args

    local spacerLocation = {PlayerCastingBarFrame = true, PetActionBar = true, PersonalResourceDisplayFrame = true}
    local order = 1
    local spacerCount = 1

    for _, frameInfo in ipairs(Config.DEFAULT_FRAMES) do
        local name, checkbox = GetElementForFrameSelection(order, frameInfo)
        path[name] = checkbox
        order = order + 1

        if spacerLocation[frameInfo.frame] then
            path["space"..spacerCount] = {
                name = "",
                type = "header",
                order = order,
            }
            spacerCount = spacerCount + 1
            order = order + 1
        end
    end
end

local CONDITION_ENTRY_BLUEPRINT = {
    {
        name = "spacerStart",
        widget = "description",
        width = 0.1,
        allowedTypes = {child = true},
    },
    {
        name = "enable",
        widget = "toggle",
        width = 1,
        setting = "enabled",
        allowedTypes = {default = true, parent = true, child = true},
        disabledKeys = {
            child = "parent"
        },
        widthOffset = {
            child =  - 0.1 - 0.15, -- subtracting spacer and customize toggle width
        }
    },
    {
        name = "customize",
        label = L["customize"],
        widget = "toggle",
        width = 0.15,
        setting = "customize",
        allowedTypes = {child = true},
        disabledKeys = {
            child = "parentChild"
        },
        description = L["description_override"],
        dialogControl = "AutoHideUI_ToggleCog",
    },
    {
        name = "alpha",
        label = L["alpha"],
        widget = "range",
        width = 0.7,
        setting = "alpha",
        allowedTypes = {default = true, parent = true, child = true},
        disabledKeys = {
            child = "parentChildOverride"
        },
        min = 0,
        max = 1,
        bigStep = 0.1,
    },
    {
        name = "priority",
        label = L["priority"],
        widget = "toggle",
        width = 0.2,
        setting = "priority",
        allowedTypes = {default = true, parent = true, child = true},
        disabledKeys = {
            child = "parentChildOverride"
        },
        description = L["description_priority"],
        dialogControl = "AutoHideUI_ToggleStar",
    },
    {
        -- getting widgets info from a different table
        widget = "extraOptions",
        allowedTypes = {default = true, parent = true, child = true},
        disabledKeys = {
            child = "parentChildOverride"
        },
    },
    {
        name = "spacerEnd",
        widget = "description",
        width = "remaining",
        allowedTypes = {default = true, parent = true, child = true},
        widthOffset = {
            parent =  - 0.2, -- subtracting width of expand toggle
        },
    },
    {
        name = "expand",
        label = L["expand"],
        --description = L["expand"],
        widget = "toggle",
        width = 0.2,
        allowedTypes = {parent = true},
        ignoreDisabled = true,
        dialogControl = "AutoHideUI_ToggleExpand",
    },

}

local function GetConditionWidget(widgetInfo, conditionInfo)
    local conditionName = conditionInfo.name
    local widgetType = widgetInfo.widget
    local widgetName = widgetInfo.name
    local settingName = widgetInfo.setting

    -- note that we check for widgetType and widgetName
    if widgetType == "description" then
        return {
            type = "description",
            name = ""
        }

    elseif widgetName == "expand" then
        return {
            type = "toggle",
            name = function()
                if sessionOptionStates[conditionName.."Expanded"] then
                    return L["collapse"]
                else
                    return L["expand"]
                end
            end,
            get = function(info) return sessionOptionStates[conditionName.."Expanded"] end,
            set = function(info, value) sessionOptionStates[conditionName.."Expanded"] = value end,
        }
    elseif widgetType == "toggle" then
        return {
            type = "toggle",
            name = widgetInfo.label or L["label_"..conditionName],
            get = function(info) return Private.db.profile.groups[selectedGroup].conditions[conditionName][settingName] end,
            set = function(info, value) Private.db.profile.groups[selectedGroup].conditions[conditionName][settingName] = value end,
        }
    elseif widgetType == "range" then
        return {
            type = "range",
            name = widgetInfo.label,
            min = 0,
            max = 1,
            bigStep = 0.1,
            get = function(info) return Private.db.profile.groups[selectedGroup].conditions[conditionName][settingName] end,
            set = function(info, value) Private.db.profile.groups[selectedGroup].conditions[conditionName][settingName] = value end,
        }
    end
end

local function GetConditionDisabledFunc(widgetInfo, conditionInfo, entryInfo)
    if widgetInfo.ignoreDisabled then
        return nil
    end

    local conditionName, parentName = conditionInfo.name, entryInfo.parentName
    local disabledKey = widgetInfo.disabledKeys and widgetInfo.disabledKeys[entryInfo.type]

    if disabledKey == "parent" then
        return function(info)
            return not Private.db.profile.groups[selectedGroup].conditions[parentName].enabled
        end
    elseif disabledKey == "parentChild" then
        return function(info)
            local parentEnabled = Private.db.profile.groups[selectedGroup].conditions[parentName].enabled
            local selfEnabled = Private.db.profile.groups[selectedGroup].conditions[conditionName].enabled
            return not selfEnabled or not parentEnabled
        end
    elseif disabledKey == "parentChildOverride" then
        return function(info)
            local parentEnabled = Private.db.profile.groups[selectedGroup].conditions[parentName].enabled
            local selfEnabled = Private.db.profile.groups[selectedGroup].conditions[conditionName].enabled
            local overrideEnabled = Private.db.profile.groups[selectedGroup].conditions[conditionName].customize
            return not selfEnabled or not parentEnabled or not overrideEnabled
        end
    elseif widgetInfo.name ~= "enable" and not widgetInfo.ignoreDisabled  then
        return function(info)
            return not Private.db.profile.groups[selectedGroup].conditions[conditionName].enabled
        end
    else
        return nil
    end
end

local function CreateConditionWidget(widgetInfo, conditionInfo, entryInfo)

    local widget = GetConditionWidget(widgetInfo, conditionInfo)
    widget.order = entryInfo.widgetOrder
    widget.desc = conditionInfo.description or widgetInfo.description

    if widgetInfo.width == "remaining" then
        widget.width = CONDITION_MAXIMUM_WIDTH - entryInfo.totalWidth
    elseif widgetInfo.width then
        widget.width = widgetInfo.width
        entryInfo.totalWidth = entryInfo.totalWidth + widgetInfo.width
    end

    if widgetInfo.dialogControl then
        widget.dialogControl = widgetInfo.dialogControl
    end

    widget.disabled = GetConditionDisabledFunc(widgetInfo, conditionInfo, entryInfo)

    if widgetInfo.widthOffset and widgetInfo.widthOffset[entryInfo.type] then
        widget.width = widget.width + widgetInfo.widthOffset[entryInfo.type]
        entryInfo.totalWidth = entryInfo.totalWidth + widgetInfo.widthOffset[entryInfo.type]
    end

    entryInfo.conditionGroup.args[widgetInfo.name] = widget
    entryInfo.widgetOrder = entryInfo.widgetOrder + 1

    return entryInfo
end

local function GetExtraConditionOptions(conditionInfo)
    local extraOptions = conditionInfo.extraOptions

    if extraOptions then
        return extraOptions
    elseif conditionInfo.type == "child" then
        local parentConditionInfo = Config.GetDefaultConditionByName(conditionInfo.parent)
        if parentConditionInfo.extraOptions then
            return parentConditionInfo.extraOptions
        end
    end
end

local function CreateExtraConditionOptions(widgetInfo, conditionInfo, entryInfo)
    local extraOptions = GetExtraConditionOptions(conditionInfo)

    if not extraOptions then
        return entryInfo
    end

    for _, extraInfo in pairs(extraOptions) do
        local widget = CopyTable(extraInfo.widget)
        widget.get = function(info) return Private.db.profile.groups[selectedGroup].conditions[conditionInfo.name][extraInfo.settingName] end
        widget.set = function(info, value) Private.db.profile.groups[selectedGroup].conditions[conditionInfo.name][extraInfo.settingName] = value end
        widget.name = L[extraInfo.entryName]
        widget.order = entryInfo.widgetOrder
        widget.disabled = GetConditionDisabledFunc(widgetInfo, conditionInfo, entryInfo)
        entryInfo.widgetOrder = entryInfo.widgetOrder + 1
        entryInfo.conditionGroup.args[extraInfo.entryName] = widget
        entryInfo.totalWidth = entryInfo.totalWidth + widget.width
    end

    return entryInfo
end

local function CreateConditionsEntry(path, conditionInfo, order)
    local conditionName = conditionInfo.name
    local conditionType = conditionInfo.type

    local conditionGroup = {
        name = "",
        type = "group",
        inline = true,
        order = order,
        args = {},
    }

    local entryInfo = {
        type = conditionInfo.type,
        totalWidth = 0,
        widgetOrder = 1,
        conditionGroup = conditionGroup,
        parentName = conditionInfo.parent,
    }

    if entryInfo.type == "child" and conditionInfo.parent then
        conditionGroup.hidden = function()
            return not sessionOptionStates[conditionInfo.parent.."Expanded"]
        end
        conditionGroup.name = ""
        local parentGroup = path["group_" .. conditionInfo.parent]
        parentGroup.args["child_"..conditionName] = conditionGroup
    else
        path["group_" .. conditionName] = conditionGroup
    end
    order = order + 1

    for _, widgetInfo in ipairs(CONDITION_ENTRY_BLUEPRINT) do
        if widgetInfo.widget == "extraOptions" then
            entryInfo = CreateExtraConditionOptions(widgetInfo, conditionInfo, entryInfo)
        elseif widgetInfo.allowedTypes[entryInfo.type] then
            entryInfo = CreateConditionWidget(widgetInfo, conditionInfo, entryInfo)
        end
    end

    if conditionType ~= "child" then
        path["headerEnd_"..conditionName] = {
            type = "header",
            name = "",
            order = order,
        }
        order = order + 1
    end

    return order
end

local function CreateConditionsOptions()
    local path = OPTIONS_MENU.args.setup.args.tabConditions.args.group_conditionSelect.args
    local order = 5
    for _, conditionInfo in ipairs(Config.CONDITION_DEFINITIONS) do
        order = CreateConditionsEntry(path, conditionInfo, order)
    end
end

function Config.CreateOptionsMenu()
    SetupFrameSelection()
    CreateConditionsOptions()
end

------------------
-- Managing Settings
------------------

function internal.GetNewGroup(name, useDefaultFrameSelection)
    local newGroup = CopyTable(GROUP_TEMPLATE)
    newGroup.frames = GetCommonFrames()
    newGroup.conditions = GetDefaultConditions()
    newGroup.name = name

    -- use defaults if no groups exist
    if selectedGroup and not useDefaultFrameSelection then
        for frame in pairs(newGroup.frames) do
            newGroup.frames[frame] = false
        end
    end

    return newGroup
end

function Config.CheckGroupsForMissingEntries()
    -- ensuring new conditions or new sub-options for existing conditions are added to user profile.
    -- AceDB will not handle additional groups the user may have created, so we have to.

    local defaultGroup = Config.GetDefaultGroup("")

    -- iterating through all profiles
    for _, profileData in pairs(Private.db.profiles) do
        -- iterating for each group in profile
        if profileData.groups then
            for _, group in ipairs(profileData.groups) do
                -- looking for missing settings
                for k,v in pairs(defaultGroup) do
                    if not group[k] then
                        if type(v) == "table" then
                            group[k] = CopyTable(v)
                        else
                            group[k] = v
                        end
                    end
                end

                -- looking for missing conditions
                for conditionName, conditionInfo in pairs(defaultGroup.conditions) do
                    if not group.conditions[conditionName] then
                        group.conditions[conditionName] = CopyTable(conditionInfo)
                    else
                        for setting, value in pairs(conditionInfo) do
                            if group.conditions[conditionName][setting] == nil then
                                group.conditions[conditionName][setting] = value
                            end
                        end
                    end
                end

                -- checking for settings that are no longer in use
                for k,v in pairs(group) do
                    if defaultGroup[k] == nil then
                        group[k] = nil
                    end
                end

            end
        end
    end

end

function Config.GetDefaultConditionByName(conditionName)
    for _, conditionInfo in ipairs(Config.CONDITION_DEFINITIONS) do
        if conditionInfo.name == conditionName then
            return conditionInfo
        end
    end
end


function Config.GetDefaultProfile()
    local defaultGroup = Config.GetDefaultGroup(L["name_defaultGroup"])
    local defaultProfile = {
        profile = {
            manualControl = {},
            groups = {
                defaultGroup,
            }
        }
    }

    return defaultProfile
end

function Config.GetDefaultGroup(name)
    local useDefaultFrameSelection = true
    local defaultGroup = internal.GetNewGroup(name, useDefaultFrameSelection)
    return defaultGroup
end

local function OnOptionsClose()
    if Main.blizzFrame:IsVisible() then
        return
    end

    Config.HideAllHighlights()
    CloseAllPopups()
    isOptionsOpen = false
    Main.ResumeAddon()
end

local function OnOptionsOpen(frame)
    -- stopping Ace menu while Blizz menu is open.
    if frame ~= Main.blizzFrame and Main.blizzFrame:IsVisible() then
        frame:Hide()
        -- necessary to re-anchor the changelog button
        LibStub("AceConfigRegistry-3.0"):NotifyChange("AutoHideUI")
        return
    end

    UI_WIDTH, UI_HEIGHT = UIParent:GetSize()

    isOptionsOpen = true
    Main.SuspendAddon()
end

local function SetHooksForBlizzard()
    Main.blizzFrame:HookScript("OnShow", function() OnOptionsOpen(Main.blizzFrame) end)
    Main.blizzFrame:HookScript("OnHide", function() OnOptionsClose() end)
end

local function SetHooksForAce()
    hooksecurefunc(AceConfigDialog, "Open", function(_, appName)
        -- this runs every time an option is changed, not just when menu opens.
        if appName ~= "AutoHideUI" then
            return
        end

        local f = AceConfigDialog.OpenFrames[appName]
        if not f then
            return
        end

        local frame = f.frame
        f:SetStatusText(L["chatCommands"].." /autohide /autohideui")

        if not isAceHooked then
            frame:SetResizeBounds(MENU_WIDTH, MENU_HEIGHT_MIN, MENU_WIDTH, MENU_HEIGHT_MAX)
            frame:HookScript("OnShow", function() OnOptionsOpen(frame) end)
            frame:HookScript("OnHide", function() OnOptionsClose() end)
            isAceHooked = true
            OnOptionsOpen(frame) -- need to run this manually on first open
        end
    end)
end

local function SetHooksForMenus()
    SetHooksForBlizzard()
    SetHooksForAce()
end

function Config.RegisterOptions()
    -- setting profiles tab in options menu
    OPTIONS_MENU.args.profiles = AceDBOptions:GetOptionsTable(Private.db)

    AceConfig:RegisterOptionsTable("AutoHideUI", OPTIONS_MENU)
    AceConfigDialog:SetDefaultSize("AutoHideUI", MENU_WIDTH, MENU_HEIGHT)
    Main.blizzFrame = AceConfigDialog:AddToBlizOptions("AutoHideUI", "Auto Hide UI")

    SLASH_AUTOHIDEUI1 = "/autohide"
    SLASH_AUTOHIDEUI2 = "/autohideui"
    SlashCmdList["AUTOHIDEUI"] = function()
        if AceConfigDialog.OpenFrames["AutoHideUI"] then
            AceConfigDialog:Close("AutoHideUI")
        elseif not IsOtherWindowsShown() then
            AceConfigDialog:Open("AutoHideUI")
        end
    end

    SetHooksForMenus()
end

------------------
-- Misc
------------------

function Config.SetHeaderText(frame, title)
    frame.header.title:SetText(title .. " - " .. Private.db.profile.groups[selectedGroup].name)
    local textWidth = frame.header.title:GetStringWidth()
    frame.header.middle:SetWidth(textWidth + 20)
end

function Config.CreateHeader(frame)
    local header = CreateFrame("Frame", nil, frame)
    frame.header = header
    header:SetSize(40,40)
    header:SetPoint("TOP", 0, 0)

    -- the code for positioning the header graphics was taken from the Ace3 libeary
    -- middle 
    header.middle = header:CreateTexture(nil, "ARTWORK")
    header.middle:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")
    header.middle:SetTexCoord(0.31, 0.67, 0, 0.63)
    header.middle:SetPoint("TOP", 0, 12)
    header.middle:SetWidth(100)
    header.middle:SetHeight(40)

    -- left cap
    header.left = header:CreateTexture(nil, "ARTWORK")
    header.left:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")
    header.left:SetTexCoord(0.21, 0.31, 0, 0.63)
    header.left:SetPoint("RIGHT", header.middle, "LEFT")
    header.left:SetWidth(30)
    header.left:SetHeight(40)

    -- right cap
    header.right = header:CreateTexture(nil, "ARTWORK")
    header.right:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")
    header.right:SetTexCoord(0.67, 0.77, 0, 0.63)
    header.right:SetPoint("LEFT", header.middle, "RIGHT")
    header.right:SetWidth(30)
    header.right:SetHeight(40)

    -- title text
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", 0, 12)
    header.title = title
end

function Config.CreateAceLikeGroup(parent, titleText, width, height)
    local group = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    group:SetSize(width, height)

    group:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8x8",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    group:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    group:SetBackdropBorderColor(0.4, 0.4, 0.4)

    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("BOTTOMLEFT", group, "TOPLEFT", 6, 3)
    title:SetText(titleText)

    group.Title = title

    return group
end