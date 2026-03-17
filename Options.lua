local _, Private = ...
-- namespaces for functions that are called between files
local Main = Private.Main
local Config = Private.Config
-- namespace for functions that are referenced before they are defined
local internal = {}

local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local pairs, ipairs  = pairs, ipairs

local selectedGroup
local isOptionsOpen
local MENU_WIDTH = 630
local MENU_HEIGHT = 780
local MENU_HEIGHT_MIN = 400
local MENU_HEIGHT_MAX = 1000
local UI_WIDTH, UI_HEIGHT
local UI_PADDING = 5
local highlightFrames = {}

------------------
-- Widgets
------------------

AceGUI:RegisterWidgetType("AutoHideUI_CheckboxWithHooks", function()
    local widget = AceGUI:Create("CheckBox")

    widget.frame:HookScript("OnEnter", function(self)
        local frameString = self.obj.userdata.option.arg.frameString
        local frameList = Main.FetchFramesFromString(frameString)
        if frameList then
            for _,frame in pairs(frameList) do
                Config.ShowHighlight(frame)
            end
        end
    end)

    widget.frame:HookScript("OnLeave", function()
        Config.HideAllHighlights()
    end)

    return widget
end, 1)

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

-- same order as these will appear in the options
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
    },
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
    },
    {
        name = "mouseover",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
        },
        events = {
            "WORLD_CURSOR_TOOLTIP_UPDATE",
            "UPDATE_MOUSEOVER_UNIT",
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
        events = {
            "PLAYER_TARGET_CHANGED",
            "PLAYER_SOFT_FRIEND_CHANGED",
            "PLAYER_FOCUS_CHANGED",
        },
    },
    {
        name = "targetHostile",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
            softTarget = false,
        },
        events = {
            "PLAYER_TARGET_CHANGED",
            "PLAYER_SOFT_ENEMY_CHANGED",
            "PLAYER_FOCUS_CHANGED",
        },
    },
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
        description = L["descr_interactable"]
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
        description = L["descr_health"]
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
    },
    {
        name = "inVehicle",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
        },
        events = {
            "UNIT_ENTERED_VEHICLE",
            "UNIT_EXITED_VEHICLE",
        },
    },

    -- remember to add new condition function to UpdateAllConditions
}

-- also accessed in Core to reset states after loading screens
Config.DEFAULT_STATES = {
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
}

local ALPHA_PREF = {
    L["Highest"], L["Lowest"],
}

------------------
-- UI Logic
------------------

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
    for _, group in ipairs(Private.db.profile) do
        tinsert(groupNames, group.name)
    end
    return groupNames
end

function Config.SetSelectedGroup(profileChanged)
    -- keeping last selection
    if profileChanged then
        selectedGroup = 1
    elseif selectedGroup and Private.db.profile[selectedGroup] then
        return
    end

    selectedGroup = nil
    for index in ipairs(Private.db.profile) do
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

local function DeleteGroup()
    if selectedGroup then
        table.remove(Private.db.profile, selectedGroup)
        Config.SetSelectedGroup()
    end
end

local function IsFrameSelectedElsewhere(frameString)
    for index, group in pairs(Private.db.profile) do
        if index ~= selectedGroup and group.frames[frameString] then
            return true
        end
    end
    return false
end

local function DisableSelectedGroupConditions()
    for _, info in pairs(Private.db.profile[selectedGroup].conditions) do
        info.enabled = false
    end
end

local function SetSelectedGroupToDefault()
    for _, defaultInfo in pairs(Config.CONDITION_DEFINITIONS) do
        local name = defaultInfo.name
        for k,v in pairs(defaultInfo.db) do
            Private.db.profile[selectedGroup].conditions[name][k] = v
        end
    end
end

StaticPopupDialogs["AUTOHIDEUI_CREATE_GROUP"] = {
    text = L["popup_createGroup"],
    button1 = L["button_create"],
    button2 = L["button_cancel"],
    hasEditBox = true,
    timeout = 0,
    whileDead = true,

    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
        self:GetEditBox():SetText("New Group")
        self:GetEditBox():HighlightText()
    end,

    OnAccept = function(self)
        if not isOptionsOpen then
            Config.PrintOptionsOpenError()
            return
        end

        local newName = self:GetEditBox():GetText()
        if newName and newName ~= "" then
            table.insert(Private.db.profile, internal.GetNewGroup(newName))
            selectedGroup = #Private.db.profile
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

StaticPopupDialogs["AUTOHIDEUI_RENAME_GROUP"] = {
    text = L["popup_renameGroup"],
    button1 = L["button_rename"],
    button2 = L["button_cancel"],
    hasEditBox = true,
    timeout = 0,
    whileDead = true,

    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
        self:GetEditBox():SetText(Private.db.profile[selectedGroup].name)
        self:GetEditBox():HighlightText()
    end,

    OnAccept = function(self)
        if not isOptionsOpen then
            Config.PrintOptionsOpenError()
            return
        end

        local newName = self:GetEditBox():GetText()
        if newName and newName ~= "" then
            Private.db.profile[selectedGroup].name = newName
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

StaticPopupDialogs["AUTOHIDEUI_DELETE_GROUP"] = {
    text = L["popup_deleteGroup"],
    button1 = L["button_delete"],
    button2 = L["button_cancel"],
    timeout = 0,
    whileDead = true,

    OnShow = function(self)
        if selectedGroup and Private.db.profile[selectedGroup] then
            self:SetText(string.format("%s|n|n-- %s --|n", L["popup_deleteGroup"], Private.db.profile[selectedGroup].name))
        end
        self:SetFrameStrata("TOOLTIP")
    end,

    OnAccept = function(self)
        if not isOptionsOpen then
            Config.PrintOptionsOpenError()
            return
        end

        DeleteGroup()
        RefreshUI()
    end,

    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
}

local function CloseAllPopups()
    StaticPopup_Hide("AUTOHIDEUI_CREATE_GROUP")
    StaticPopup_Hide("AUTOHIDEUI_RENAME_GROUP")
    StaticPopup_Hide("AUTOHIDEUI_DELETE_GROUP")
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
        -- descr_frames = {
        --     type = "description",
        --     name = L["descr_frames"],
        --     fontSize = "medium",
        --     order = 2,
        -- },
        -- spacer_frames2 = {
        --     type = "description",
        --     name = "",
        --     fontSize = "small",
        --     order = 4,
        -- },
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
                    width = 0.05,
                    order = 2
                },
                descr_customFrames = {
                    type = "description",
                    fontSize = "medium",
                    name = L["descr_customFrames"].."|n",
                    width = 1.95,
                    order = 3,
                },
                editbox_customFrames = {
                    type = "input",
                    name = "",
                    width = "full",
                    get = function(info) return Private.db.profile[selectedGroup].config.customFrames end,
                    set = function(info, value) Private.db.profile[selectedGroup].config.customFrames = value end,
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
                    get = function() return Private.db.profile[selectedGroup].config.fadeOutDelay end,
                    set = function(_, value) Private.db.profile[selectedGroup].config.fadeOutDelay = value end,
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
                    get = function() return Private.db.profile[selectedGroup].config.fadeInDelay end,
                    set = function(_, value) Private.db.profile[selectedGroup].config.fadeInDelay = value end,
                    order = 6,
                },
                fadeDuration = {
                    type = "range",
                    name = L["slider_fadeDuration"],
                    width = 1,
                    min = 0,
                    max = 5,
                    softMax = 1,
                    get = function() return Private.db.profile[selectedGroup].config.timeToFade end,
                    set = function(_, value) Private.db.profile[selectedGroup].config.timeToFade = value end,
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
                    get = function() return Private.db.profile[selectedGroup].config.idleAlpha end,
                    set = function(_, value) Private.db.profile[selectedGroup].config.idleAlpha = value end,
                    order = 1,
                },
                checkbox_forceAlpha = {
                    type = "toggle",
                    name = L["checkbox_forceAlpha"],
                    desc = L["desc_forceAlpha"],
                    width = 1.5,
                    get = function(info) return Private.db.profile[selectedGroup].config.forceAlpha end,
                    set = function(info, value) Private.db.profile[selectedGroup].config.forceAlpha = value end,
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
                    get = function() return Private.db.profile[selectedGroup].config.normalAlphaPref end,
                    set = function(_, value) Private.db.profile[selectedGroup].config.normalAlphaPref = value end,
                    desc = L["tooltip_alphaPref"],
                    order = 6,
                },
                dropdownPrioAlphaPref = {
                    name = L["dropdown_prioAlphaPref"],
                    type = "select",
                    width = 1.3,
                    values = function() return ALPHA_PREF end,
                    get = function() return Private.db.profile[selectedGroup].config.prioAlphaPref end,
                    set = function(_, value) Private.db.profile[selectedGroup].config.prioAlphaPref = value end,
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
            name = "|n"..L["descr_conditions"].."|n",
            fontSize = "medium",
            order = 5,
        },
        descrPrioConditions = {
            type = "description",
            name = "|n"..L["descr_prioConditions"].."|n|n",
            fontSize = "medium",
            order = 6,
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
                }
                -- rest is filled in later
            }, 
        },
    },
    order = 23
}

local EXTRA_CONDITION_ELEMENTS = {
    -- default elements occupy order 5-7
    mounted = {
        druidForms = {
            name = L["dropdown_druidForms"],
            type = "select",
            width = 0.8,
            values = function() return {L["dropdownOption_druid1"], L["dropdownOption_druid2"], L["dropdownOption_druid3"]} end,
            get = function() return Private.db.profile[selectedGroup].conditions.mounted.druidForms end,
            set = function(_, value) Private.db.profile[selectedGroup].conditions.mounted.druidForms = value end,
            order = 10,
        },
    },
    flying = {
        style = {
            name = L["dropdown_flightStyle"],
            type = "select",
            width = 0.8,
            values = function() return {L["dropdownOption_flight1"], L["dropdownOption_flight2"], L["dropdownOption_flight3"]} end,
            get = function() return Private.db.profile[selectedGroup].conditions.flying.style end,
            set = function(_, value) Private.db.profile[selectedGroup].conditions.flying.style = value end,
            order = 10,
        },
    },
    health = {
        dropdown_health = {
            name = L["dropdown_health"],
            desc = L["descr_health"],
            type = "select",
            width = 0.8,
            values = function() return {L["dropdownOption_health1"], L["dropdownOption_health2"]} end,
            get = function() return Private.db.profile[selectedGroup].conditions.health.style end,
            set = function(_, value) Private.db.profile[selectedGroup].conditions.health.style = value end,
            order = 10,
        },
    },
    targetFriendly = {
        checkbox_softTargetFriendly = {
            name = L["checkbox_softTarget"],
            desc = L["descr_softTarget"],
            type = "toggle",
            get = function() return Private.db.profile[selectedGroup].conditions.targetFriendly.softTarget end,
            set = function(_, value) Private.db.profile[selectedGroup].conditions.targetFriendly.softTarget = value end,
            width = 0.8,
            order = 10,
        }
    },
    targetHostile = {
        checkbox_softTargetHostile = {
            name = L["checkbox_softTarget"],
            desc = L["descr_softTarget"],
            type = "toggle",
            get = function() return Private.db.profile[selectedGroup].conditions.targetHostile.softTarget end,
            set = function(_, value) Private.db.profile[selectedGroup].conditions.targetHostile.softTarget = value end,
            width = 0.8,
            order = 10,
        }
    },
    interactable = {
        checkbox_interactable = {
            name = L["checkbox_excludeNPCs"],
            desc = L["descr_excludeNPCs"],
            type = "toggle",
            get = function() return Private.db.profile[selectedGroup].conditions.interactable.excludeNPCs end,
            set = function(_, value) Private.db.profile[selectedGroup].conditions.interactable.excludeNPCs = value end,
            width = 0.8,
            order = 10,
        }
    },

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
                    --fontSize = "large",
                    name = Main.ColorString(L["descr_groups"], "gold"),
                    order = 1,
                },
                groupSelection = {
                    name = L["dropdown_groupSelect"],
                    type = "select",
                    values = function() return GetGroupNames() end,
                    get = function() return selectedGroup end,
                    set = function(_, value) selectedGroup = value end,
                    width = 1,
                    order = 3,
                },
                buttonNew = {
                    name = L["button_newGroup"],
                    type = "execute",
                    width = 0.9,
                    func = function() StaticPopup_Show("AUTOHIDEUI_CREATE_GROUP") end,
                    order = 5,
                },
                buttonRename = {
                    name = L["button_renameGroup"],
                    type = "execute",
                    width = 0.7,
                    func = function() StaticPopup_Show("AUTOHIDEUI_RENAME_GROUP") end,
                    order = 10,
                },
                buttonDelete = {
                    name = L["button_deleteGroup"],
                    type = "execute",
                    width = 0.7,
                    func = function() StaticPopup_Show("AUTOHIDEUI_DELETE_GROUP") end,
                    order = 15,
                },
                tabFrames = OPTIONS_TAB_FRAMES,
                tabFade = OPTIONS_TAB_FADE,
                tabConditions = OPTIONS_TAB_CONDITIONS,
            },
        },
        -- profiles is set later when db has actually been initialized
    },
}

local function GetElementForFrameSelection(order, frameInfo)
    local frameString = frameInfo.frame
    local checkbox = {
        name = frameInfo.label,
        type = "toggle",
        get = function(info) return Private.db.profile[selectedGroup].frames[frameString] end,
        set = function(info, value) Private.db.profile[selectedGroup].frames[frameString] = value end,
        disabled = function(info)
            return IsFrameSelectedElsewhere(frameString)
        end,
        dialogControl = "AutoHideUI_CheckboxWithHooks",
        desc = frameInfo.description, -- most times is nil
        order = order,
        arg = {frameString = frameString},
    }

    return frameInfo.frame, checkbox
end

local function SetupFrameSelection()
    local path = OPTIONS_MENU.args.setup.args.tabFrames.args.group_defaultFrames.args

    local spacerLocation = {PlayerCastingBarFrame = true, PetActionBar = true, DebuffFrame = true}
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

local function SetElementForConditionSelection(path, info, order)
    local name = info.name
    local label = L["label_"..name]
    local pathDB = Private.db
    local DisabledFunc = function()
        return not pathDB.profile[selectedGroup].conditions[name].enabled
    end

    local spacer = {
        type = "description",
        name = "",
        order = order,
    }

    local enable = {
        name = label,
        type = "toggle",
        get = function(info) return pathDB.profile[selectedGroup].conditions[name].enabled end,
        set = function(info, value) pathDB.profile[selectedGroup].conditions[name].enabled = value end,
        desc = info.description,
        width = 1.1,
        order = order,
    }
    order = order + 1

    local slider = {
        type = "range",
        name = L["alpha"],
        width = 0.7,
        min = 0,
        max = 1,
        get = function() return pathDB.profile[selectedGroup].conditions[name].alpha end,
        set = function(_, value) pathDB.profile[selectedGroup].conditions[name].alpha = value end,
        disabled = DisabledFunc,
        order = order
    }
    order = order + 1

    local priority = {
        name = L["priority"],
        type = "toggle",
        get = function(info) return pathDB.profile[selectedGroup].conditions[name].priority end,
        set = function(info, value) pathDB.profile[selectedGroup].conditions[name].priority = value end,
        disabled = DisabledFunc,
        width = 0.35,
        order = order,
    }
    order = order + 1



    path["spacer_"..name] = spacer
    path["enable_"..name] = enable
    path["priority_"..name] = priority
    path["slider_"..name] = slider

    local extraConditionElements = EXTRA_CONDITION_ELEMENTS[name]
    if extraConditionElements then
        for extraName, extraElement in pairs(extraConditionElements) do
            extraElement.order = order
            extraElement.disabled = DisabledFunc
            path[extraName] = extraElement
            order = order + 1
        end
    end

    return order

end

local function SetupConditionSelection()
    local path = OPTIONS_MENU.args.setup.args.tabConditions.args.group_conditionSelect.args
    local order = 5
    for index, info in ipairs(Config.CONDITION_DEFINITIONS) do
        order = SetElementForConditionSelection(path, info, order)
    end
end

function Config.CreateOptionsMenu()
    SetupFrameSelection()
    SetupConditionSelection()
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

function Config.CheckGroupsForMissingEntries(defaultGroup)
    -- ensuring new conditions or new sub-options for existing conditions are added to user profile.
    -- AceDB will not handle additional groups the user may have created, so we have to.
    for _, group in ipairs(Private.db.profile) do
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
    end
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

        if not Private.isAceHooked then
            frame:SetResizeBounds(MENU_WIDTH, MENU_HEIGHT_MIN, MENU_WIDTH, MENU_HEIGHT_MAX)
            frame:HookScript("OnShow", function() OnOptionsOpen(frame) end)
            frame:HookScript("OnHide", function() OnOptionsClose() end)
            Private.isAceHooked = true
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
        elseif not AutoHideUIFrameFinderFrame:IsShown() then
            AceConfigDialog:Open("AutoHideUI")
        end
    end

    SetHooksForMenus()

    -- C_Timer.After(1, function()
    --     AceConfigDialog:Open("AutoHideUI")
    -- end)
end
