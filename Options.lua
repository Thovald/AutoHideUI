local _, Private = ...
-- namespaces for functions that are called between files
local main = Private.main
local config = Private.config
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
local MENU_HEIGHT = 750
local MENU_HEIGHT_MIN = 400
local MENU_HEIGHT_MAX = 1000
local highlightFrames = {}

------------------
-- Widgets
------------------

AceGUI:RegisterWidgetType("MyAddon_CheckboxWithHooks", function()
    local widget = AceGUI:Create("CheckBox")

    widget.frame:HookScript("OnEnter", function(self)
        local frameString = self.obj.userdata.option.arg.frameString
        local frameList = main.FetchFramesFromString(frameString)
        if frameList then
            for _,frame in pairs(frameList) do
                config.ShowHighlight(frame)
            end
        end
    end)

    widget.frame:HookScript("OnLeave", function()
        config.HideAllHighlights()
    end)

    return widget
end, 1)

------------------
-- UI Data
------------------

-- same order as these will appear in the options
config.DEFAULT_FRAMES = {
    -- unitframes
    { frame = "PlayerFrame", label = L["Player Frame"], enabled = true },
    { frame = "TargetFrame", label = L["Target Frame"], enabled = true },
    { frame = "FocusFrame", label = L["Focus Frame"], enabled = false },
    { frame = "PetFrame", label = L["Pet Frame"], enabled = true },
    { frame = "PlayerCastingBarFrame", label = L["Player Castbar"], enabled = false },
    -- actionbars
    { frame = "MainActionBar", label = L["ActionBar 1"], enabled = true },
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
    -- other
    { frame = "DamageMeter", label = L["Damage Meter"], enabled = true },
    { frame = "BagsBar", label = L["Bags Bar"], enabled = true },
    { frame = "MicroMenu", label = L["Micro Menu"], enabled = false },
    { frame = "ObjectiveTrackerFrame", label = L["Objectives Frame"], enabled = false },

}

local function GetCommonFrames()
    local frameList = {}
    for _, frameInfo in ipairs(config.DEFAULT_FRAMES) do
        frameList[frameInfo.frame] = frameInfo.enabled
    end
    return frameList
end

-- same order as these will appear in the options
config.CONDITION_DEFINITIONS = {
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
        },
        events = {
            "PLAYER_TARGET_CHANGED",
        },
    },
    {
        name = "targetHostile",
        db = {
            enabled = true,
            alpha = 1,
            priority = false,
        },
        events = {
            "PLAYER_TARGET_CHANGED",
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
            threshold = 0.75,
            priority = false,
        },
        events = {
            "UNIT_HEALTH",
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
config.DEFAULT_STATES = {
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
    "Highest", "Lowest",
}

------------------
-- UI Logic
------------------

function config.PrintOptionsOpenError()
    local title = main.GetErrorTitleString()
    local message = main.ColorString(L["error_optionsOpen"], "red")
    print(title..message)
end

local function GetDefaultConditions()
    local conditions = {}
    for _, condition in ipairs(config.CONDITION_DEFINITIONS) do
        conditions[condition.name] = CopyTable(condition.db)
    end
    return conditions
end

local function CreateNewHighlight()
    -- to highlight frames when user hovers over frame selection options.
    local hl = CreateFrame("Frame")
    local tex = hl:CreateTexture()
    tex:SetAllPoints()
    tex:SetColorTexture(0, 1, 0, 1)
    hl.tex = tex
    hl:Hide()
    hl:SetFrameStrata("HIGH")
    hl:SetAlpha(0.6)
    local hlInfo = {frame = hl, inUse = false}
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

function config.ShowHighlight(frame)
    local highlight = GetNextHighlight()

    if frame:IsVisible() then
        highlight.tex:SetColorTexture(0, 1, 0, 1)
    else
        highlight.tex:SetColorTexture(1, 1, 0, 1)
    end

    highlight:SetAllPoints(frame)
    highlight:Show()
end

function config.HideAllHighlights()
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

function config.SetSelectedGroup(profileChanged)
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
        config.SetSelectedGroup()
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
            config.PrintOptionsOpenError()
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
            config.PrintOptionsOpenError()
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
            config.PrintOptionsOpenError()
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
        descr_frames = {
            type = "description",
            name = L["descr_frames"],
            fontSize = "medium",
            order = 2,
        },
        spacer_frames2 = {
            type = "description",
            name = "",
            fontSize = "small",
            order = 4,
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
                descr_customFrames = {
                    type = "description",
                    fontSize = "medium",
                    name = L["descr_customFrames"].."|n",
                    order = 1,
                },
                editbox_customFrames = {
                    type = "input",
                    name = "",
                    width = "full",
                    get = function(info) return Private.db.profile[selectedGroup].config.customFrames end,
                    set = function(info, value) Private.db.profile[selectedGroup].config.customFrames = value end,
                    multiline = true,
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
            args = {}, -- filled in later
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
                    name = main.ColorString(L["descr_groups"], "gold"),
                    order = 1,
                },
                groupSelection = {
                    name = L["dropdown_groupSelect"],
                    type = "select",
                    values = function() return GetGroupNames() end,
                    get = function() return selectedGroup end,
                    set = function(_, value) selectedGroup = value end,
                    order = 3,
                },
                buttonNew = {
                    name = L["button_newGroup"],
                    type = "execute",
                    width = 0.7,
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
        dialogControl = "MyAddon_CheckboxWithHooks",
        order = order,
        arg = {frameString = frameString},
    }

    return frameInfo.frame, checkbox
end

local function SetupFrameSelection()
    local path = OPTIONS_MENU.args.setup.args.tabFrames.args.group_defaultFrames.args

    local spacerLocation = {PlayerCastingBarFrame = true, PetActionBar = true, BuffBarCooldownViewer = true}
    local order = 1
    local spacerCount = 1

    for _, frameInfo in ipairs(config.DEFAULT_FRAMES) do
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
        disabled = function(info)
            return false
        end,
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
        order = order
    }
    order = order + 1

    local priority = {
        name = L["priority"],
        type = "toggle",
        get = function(info) return pathDB.profile[selectedGroup].conditions[name].priority end,
        set = function(info, value) pathDB.profile[selectedGroup].conditions[name].priority = value end,
        disabled = function(info)
            return false
        end,
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
            path[extraName] = extraElement
            order = order + 1
        end
    end

    return order

end

local function SetupConditionSelection()
    local path = OPTIONS_MENU.args.setup.args.tabConditions.args.group_conditionSelect.args
    local order = 1
    for index, info in ipairs(config.CONDITION_DEFINITIONS) do
        order = SetElementForConditionSelection(path, info, order)
    end
end

function config.CreateOptionsMenu()
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

function config.GetDefaultGroup(name)
    local useDefaultFrameSelection = true
    local defaultGroup = internal.GetNewGroup(name, useDefaultFrameSelection)
    return defaultGroup
end

local function OnOptionsClose()
    if main.blizzFrame:IsVisible() then
        return
    end

    config.HideAllHighlights()
    CloseAllPopups()
    isOptionsOpen = false
    main.ResumeAddon()
end

local function OnOptionsOpen(frame)
    -- stopping Ace menu while Blizz menu is open.
    if frame ~= main.blizzFrame and main.blizzFrame:IsVisible() then
        frame:Hide()
        return
    end

    isOptionsOpen = true
    main.SuspendAddon()
end

local function SetHooksForBlizzard()
    main.blizzFrame:HookScript("OnShow", function() OnOptionsOpen(main.blizzFrame) end)
    main.blizzFrame:HookScript("OnHide", function() OnOptionsClose() end)
end

local function SetHooksForAce()
    hooksecurefunc(AceConfigDialog, "Open", function(_, appName)
        -- this runs every time an option is changed, not just when menu opens.
        if appName ~= "AutoHideUI" then return end

        local f = AceConfigDialog.OpenFrames[appName]
        if not f then return end

        local frame = f.frame

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

function config.RegisterOptions()
    -- setting profiles tab in options menu
    OPTIONS_MENU.args.profiles = AceDBOptions:GetOptionsTable(Private.db)

    AceConfig:RegisterOptionsTable("AutoHideUI", OPTIONS_MENU)
    AceConfigDialog:SetDefaultSize("AutoHideUI", MENU_WIDTH, MENU_HEIGHT)
    main.blizzFrame = AceConfigDialog:AddToBlizOptions("AutoHideUI", "Auto Hide UI")

    SLASH_AUTOHIDEUI1 = "/autohide"
    SLASH_AUTOHIDEUI2 = "/autohideui"
    SlashCmdList["AUTOHIDEUI"] = function()
        if AceConfigDialog.OpenFrames["AutoHideUI"] then
            AceConfigDialog:Close("AutoHideUI")
        else
            AceConfigDialog:Open("AutoHideUI")
        end
    end

    SetHooksForMenus()

    -- C_Timer.After(1, function()
    --     AceConfigDialog:Open("AutoHideUI")
    -- end)
end
