local _, Private = ...
local Main = Private.Main
local Config = Private.Config
local ConditionsTab = Private.ConditionsTab
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local sessionOptionStates = {} -- misc option states that don't need to be stored in SV
local CONDITION_MAXIMUM_WIDTH = 2.95

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Data
-- ─────────────────────────────────────────────────────────────────────────────

-- same order as these will appear in the options.
-- it's important to list parents before their children!
ConditionsTab.CONDITION_DEFINITIONS = {
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
    -- ─────────────────────────────────────────────────────────────────────────────----
    -- START instance
    -- ─────────────────────────────────────────────────────────────────────────────----
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
    -- ─────────────────────────────────────────────────────────────────────────────----
    -- END instance
    -- ─────────────────────────────────────────────────────────────────────────────----
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
    -- ─────────────────────────────────────────────────────────────────────────────----
    -- START target
    -- ─────────────────────────────────────────────────────────────────────────────----
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
            customize = false,
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
            customize = false,
        },
        type = "child",
        parent = "target",
    },
    -- ─────────────────────────────────────────────────────────────────────────────----
    -- END target 
    -- ─────────────────────────────────────────────────────────────────────────────----

    -- ─────────────────────────────────────────────────────────────────────────────----
    -- START focus 
    -- ─────────────────────────────────────────────────────────────────────────────----
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
            customize = false,
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
            customize = false,
        },
        type = "child",
        parent = "focus",
    },
    -- ─────────────────────────────────────────────────────────────────────────────----
    -- END focus
    -- ─────────────────────────────────────────────────────────────────────────────----
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
        descr = L["descr_interactable"],
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
        descr = L["descr_health"],
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

local CONDITIONS_TAB = {
    name = L["tab_fadeConditions"],
    type = "group",
    disabled = Config.NoSelectedGroup,
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
                    func = function() ConditionsTab.DisableSelectedGroupConditions() end,
                    order = 1,
                },
                buttonReset = {
                    name = L["button_reset"],
                    type = "execute",
                    confirm = true,
                    width = 1,
                    func = function()  ConditionsTab.SetSelectedGroupToDefault() end,
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
        width = 0.9,
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
        order = 99,
    },

}

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Logic
-- ─────────────────────────────────────────────────────────────────────────────

function ConditionsTab.GetDefaultConditions()
    local conditions = {}
    for _, condition in ipairs(ConditionsTab.CONDITION_DEFINITIONS) do
        conditions[condition.name] = CopyTable(condition.db)
    end
    return conditions
end

function ConditionsTab.DisableSelectedGroupConditions()
    for _, info in pairs(Private.db.profile.groups[Config.selectedGroup].conditions) do
        info.enabled = false
    end
end

function ConditionsTab.SetSelectedGroupToDefault()
    for cName, cDB in pairs(ConditionsTab.GetDefaultConditions()) do
        Private.db.profile.groups[Config.selectedGroup].conditions[cName] = cDB
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Elements
-- ─────────────────────────────────────────────────────────────────────────────

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
            get = function(info) return Private.db.profile.groups[Config.selectedGroup].conditions[conditionName][settingName] end,
            set = function(info, value) Private.db.profile.groups[Config.selectedGroup].conditions[conditionName][settingName] = value end,
        }
    elseif widgetType == "range" then
        return {
            type = "range",
            name = widgetInfo.label,
            min = 0,
            max = 1,
            bigStep = 0.1,
            get = function(info) return Private.db.profile.groups[Config.selectedGroup].conditions[conditionName][settingName] end,
            set = function(info, value) Private.db.profile.groups[Config.selectedGroup].conditions[conditionName][settingName] = value end,
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
            return not Private.db.profile.groups[Config.selectedGroup].conditions[parentName].enabled
        end
    elseif disabledKey == "parentChild" then
        return function(info)
            local parentEnabled = Private.db.profile.groups[Config.selectedGroup].conditions[parentName].enabled
            local selfEnabled = Private.db.profile.groups[Config.selectedGroup].conditions[conditionName].enabled
            return not selfEnabled or not parentEnabled
        end
    elseif disabledKey == "parentChildOverride" then
        return function(info)
            local parentEnabled = Private.db.profile.groups[Config.selectedGroup].conditions[parentName].enabled
            local selfEnabled = Private.db.profile.groups[Config.selectedGroup].conditions[conditionName].enabled
            local overrideEnabled = Private.db.profile.groups[Config.selectedGroup].conditions[conditionName].customize
            return not selfEnabled or not parentEnabled or not overrideEnabled
        end
    elseif widgetInfo.name ~= "enable" and not widgetInfo.ignoreDisabled  then
        return function(info)
            return not Private.db.profile.groups[Config.selectedGroup].conditions[conditionName].enabled
        end
    else
        return nil
    end
end

local function CreateConditionWidget(widgetInfo, conditionInfo, entryInfo)

    local widget = GetConditionWidget(widgetInfo, conditionInfo)
    widget.order = widgetInfo.order or entryInfo.widgetOrder
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
        widget.get = function(info) return Private.db.profile.groups[Config.selectedGroup].conditions[conditionInfo.name][extraInfo.settingName] end
        widget.set = function(info, value) Private.db.profile.groups[Config.selectedGroup].conditions[conditionInfo.name][extraInfo.settingName] = value end
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

function ConditionsTab.CreateOptions()
    local root = CopyTable(CONDITIONS_TAB)
    local conditionsPath = root.args.group_conditionSelect.args

    local order = 5
    for _, conditionInfo in ipairs(ConditionsTab.CONDITION_DEFINITIONS) do
        order = CreateConditionsEntry(conditionsPath, conditionInfo, order)
    end

    return root
end