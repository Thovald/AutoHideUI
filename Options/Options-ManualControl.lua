local _, Private = ...
local Main = Private.Main
local Config = Private.Config
local ManualControl = Private.ManualControl
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local capturingKeybind = false

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Data
-- ─────────────────────────────────────────────────────────────────────────────

local MANUAL_CONTROL_DEFAULTS = {
    enabled = true,
    name = L["button_newOverride"],
    alpha = 1,
    keybind = "",
    keybindDisplay = "",
    macro = "",
    groupStyle = 1,
    groups = {},
}

local MANUAL_CONTROL_TEMPLATE = {
    name = "",
    type = "group",
    order = 1,
    args = {
        toggleEnable = {
            type = "toggle",
            name = L["enable"],
            width = 0.7,
            order = 5,
            get = function(info) return Private.db.profile.manualControl[info.arg.index].enabled end,
            set = function(info, value) Private.db.profile.manualControl[info.arg.index].enabled = value end,
            arg = {},
        },
        spacer1 = {
            type = "description",
            name = " ",
            width = 0.9,
            order = 6,
        },
        buttonRename = {
            name = L["button_rename"],
            type = "execute",
            width = 0.7,
            func = function(info) ManualControl.ShowRenameDialog(info.arg.index) end,
            order = 10,
            arg = {},
        },
        spacerRename = {
            type = "description",
            name = " ",
            width = 0.1,
            order = 11,
        },
        buttonDelete = {
            name = L["button_delete"],
            type = "execute",
            width = 0.7,
            func = function(info) ManualControl.ShowDeleteDialog(info.arg.index) end,
            order = 15,
            arg = {},
        },
        alpha = {
            type = "range",
            name = L["alpha"],
            disabled = function(info) return not Private.db.profile.manualControl[info.arg.index].enabled end,
            width = 0.9,
            min = 0,
            max = 1,
            bigStep = 0.1,
            get = function(info) return Private.db.profile.manualControl[info.arg.index].alpha end,
            set = function(info, value) Private.db.profile.manualControl[info.arg.index].alpha = value end,
            order = 20,
            arg = {},
        },
        spacerAlpha = {
            type = "description",
            name = " ",
            width = 0.2,
            order = 21,
        },
        buttonHotkey = {
            name = function(info)
                local recording = capturingKeybind == info.arg.index and L["button_setHotkeyRecording"]
                local keybind = Private.db.profile.manualControl[info.arg.index].keybindDisplay ~= "" and Private.db.profile.manualControl[info.arg.index].keybindDisplay
                return recording or keybind or L["button_setHotkey"]
            end,
            desc = L["description_setHotkey"],
            disabled = function(info) return not Private.db.profile.manualControl[info.arg.index].enabled end,
            type = "execute",
            width = 0.9,
            func = function(info) ManualControl.RecordKeybind(info.arg.index) end,
            order = 25,
            arg = {},
        },
        spacerHotkey = {
            type = "description",
            name = " ",
            width = 0.2,
            order = 26,
        },
        inputMacro = {
            type = "input",
            name = L["input_macro"],
            desc = L["description_macro"],
            disabled = function(info) return not Private.db.profile.manualControl[info.arg.index].enabled end,
            width = 0.9,
            get = function(info) return Private.db.profile.manualControl[info.arg.index].macro end,
            set = function(info, value) Private.db.profile.manualControl[info.arg.index].macro = value end,
            order = 30,
            arg = {},
        },
        spacerGroups = {
            type = "description",
            name = " ",
            width = 3,
            order = 31,
        },
        groupAffected = {
            name = L["dropdown_affectedGroups"],
            type = "group",
            order = 35,
            args = {
                dropDownGroups = {
                    name = "",
                    type = "select",
                    values = {L["dropdownOption_affectedGroups1"], L["dropdownOption_affectedGroups2"]},
                    width = 0.8,
                    disabled = function(info) return not Private.db.profile.manualControl[info.arg.index].enabled end,
                    get = function(info) return Private.db.profile.manualControl[info.arg.index].groupStyle end,
                    set = function(info, value) Private.db.profile.manualControl[info.arg.index].groupStyle = value end,
                    order = 0,
                    arg = {},
                },
                spacerGroups = {
                    type = "description",
                    name = " ",
                    width = 2,
                    order = 1,
                },
                spacerGroups2 = {
                    type = "description",
                    name = " ",
                    width = 4,
                    order = 2,
                },
            },
        }
    },
}

local MANUAL_CONTROL_TAB = {
    name = L["tab_manualControl"],
    type = "group",
    disabled = Config.NoSelectedGroup,
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
            width = 1,
            func = function() ManualControl.ShowCreateDialog() end,
            order = 10,
        },
        overrideContainer = {
            type = "group",
            name = "",
            inline = true,
            order = 15,
            args = {}
        },
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Keybind Capture
-- ─────────────────────────────────────────────────────────────────────────────

local FORBIDDEN_KEYS = {
    UNKNOWN = true,

    LSHIFT = true,
    RSHIFT = true,

    LCTRL = true,
    RCTRL = true,

    LALT = true,
    RALT = true,

    LeftButton = true,
    RightButton = true,
}

local DISPLAY_NAMES = {
    BUTTON1 = "Mouse Left",
    BUTTON2 = "Mouse Right",
    BUTTON3 = "Mouse Middle",
    BUTTON4 = "Mouse 4",
    BUTTON5 = "Mouse 5",

    MOUSEWHEELUP = "Wheel Up",
    MOUSEWHEELDOWN = "Wheel Down",

    NUMPADPLUS = "Numpad +",
    NUMPADMINUS = "Numpad -",

    PAGEUP = "Page Up",
    PAGEDOWN = "Page Down",
}

do
    local captureFrame = CreateFrame("Frame", nil, UIParent)

    captureFrame:EnableKeyboard(false)
    captureFrame:EnableMouse(false)
    captureFrame:SetPropagateKeyboardInput(false)
    captureFrame:SetFrameStrata("TOOLTIP")
    captureFrame:SetAllPoints(UIParent)
    captureFrame:Hide()

    captureFrame:SetScript("OnKeyDown", function(_, key)
        ManualControl.HandleBinding(key)
    end)

    captureFrame:SetScript("OnMouseDown", function(_, button)
        ManualControl.HandleBinding(button)
    end)

    ManualControl.captureFrame = captureFrame
end

 function ManualControl.RecordKeybind(index)
    capturingKeybind = index
    Config.RefreshUI()
    ManualControl.captureFrame.db = Private.db.profile.manualControl[index]
    ManualControl.captureFrame:EnableKeyboard(true)
    ManualControl.captureFrame:EnableMouse(true)
    ManualControl.captureFrame:Show()
end

local function NormalizeKey(key)

    if key == "LeftButton" then
        return "BUTTON1"
    elseif key == "RightButton" then
        return "BUTTON2"
    elseif key == "MiddleButton" then
        return "BUTTON3"
    end

    return key
end

local function BuildBindingData(key)

    key = NormalizeKey(key)

    local bindingParts = {}
    local displayParts = {}

    if IsControlKeyDown() then
        table.insert(bindingParts, "CTRL")
        table.insert(displayParts, "Ctrl")
    end

    if IsShiftKeyDown() then
        table.insert(bindingParts, "SHIFT")
        table.insert(displayParts, "Shift")
    end

    if IsAltKeyDown() then
        table.insert(bindingParts, "ALT")
        table.insert(displayParts, "Alt")
    end

    table.insert(bindingParts, key)

    table.insert(
        displayParts,
        DISPLAY_NAMES[key] or key
    )

    return {
        binding = table.concat(bindingParts, "-"),
        display = table.concat(displayParts, "+"),
    }
end

local function StopCapture()
    capturingKeybind = false
    ManualControl.captureFrame:EnableKeyboard(false)
    ManualControl.captureFrame:EnableMouse(false)
    ManualControl.captureFrame:Hide()

    Config.RefreshUI()
    print("Binding capture ended")
end



function ManualControl.HandleBinding(key)

    if key == "ESCAPE" then
        ManualControl.captureFrame.db.keybind = ""
        ManualControl.captureFrame.db.keybindDisplay = ""
        StopCapture()
        return
    end

    if FORBIDDEN_KEYS[key] then
        return
    end

    local bindData = BuildBindingData(key)

    print("binding:", bindData.binding)
    print("display:", bindData.display)
    ManualControl.captureFrame.db.keybind = bindData.binding
    ManualControl.captureFrame.db.keybindDisplay = bindData.display

    StopCapture()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Managing Settings
-- ─────────────────────────────────────────────────────────────────────────────

function ManualControl.ShowCreateDialog()
    --StaticPopup_Hide("AUTOHIDEUI_CREATE_ENTITY")
    StaticPopupDialogs["AUTOHIDEUI_CREATE_ENTITY"].text = L["popup_createOverride"]
    Config.popupContext.editBoxText = L["name_newOverride"]

    Config.popupContext.callbacks.createOnAccept = function(name)
        local newEntry = CopyTable(MANUAL_CONTROL_DEFAULTS)
        newEntry.name = name
        tinsert(Private.db.profile.manualControl, newEntry)
    end

    StaticPopup_Show("AUTOHIDEUI_CREATE_ENTITY")
end

function ManualControl.ShowRenameDialog(index)
    --StaticPopup_Hide("AUTOHIDEUI_RENAME_ENTITY")
    StaticPopupDialogs["AUTOHIDEUI_RENAME_ENTITY"].text = L["popup_renameOverride"]
    Config.popupContext.editBoxText = Private.db.profile.manualControl[index].name

    Config.popupContext.callbacks.renameOnAccept = function(name)
        Private.db.profile.manualControl[index].name = name
    end

    StaticPopup_Show("AUTOHIDEUI_RENAME_ENTITY")
end

function ManualControl.ShowDeleteDialog(index)
    --StaticPopup_Hide("AUTOHIDEUI_DELETE_ENTITY")
    StaticPopupDialogs["AUTOHIDEUI_DELETE_ENTITY"].text = L["popup_deleteOverride"]

    Config.popupContext.callbacks.deleteOnShow = function(self)
        self:SetText(string.format("%s|n|n-- %s --|n", L["popup_deleteOverride"], Private.db.profile.manualControl[index].name))
    end

    Config.popupContext.callbacks.deleteOnAccept = function()
        tremove(Private.db.profile.manualControl, index)
    end

    StaticPopup_Show("AUTOHIDEUI_DELETE_ENTITY")
end

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Elements
-- ─────────────────────────────────────────────────────────────────────────────

function ManualControl.CreateOptions()
    local root = CopyTable(MANUAL_CONTROL_TAB)
    local order = 1

    for overrideIndex, overrideInfo in ipairs(Private.db.profile.manualControl) do
        -- separator
        local header = {
            type = "header",
            width = "full",
            name = "",
            order = order,
        }
        root.args.overrideContainer.args["header" .. overrideIndex] = header
        order = order + 1

        -- main options
        local overrideGroup = CopyTable(MANUAL_CONTROL_TEMPLATE)
        overrideGroup.name = overrideInfo.name
        overrideGroup.order = order
        order = order + 1

        for _, widget in pairs(overrideGroup.args) do
            if widget.arg then
                widget.arg.index = overrideIndex
            end
        end

        -- user groups
        overrideGroup.args.groupAffected.args.dropDownGroups.arg.index = overrideIndex
        for groupIndex, groupInfo in ipairs(Private.db.profile.groups) do
            overrideGroup.args.groupAffected.args["toggleGroup"..groupIndex] = {
                type = "toggle",
                name = groupInfo.name,
                get = function(info) return Private.db.profile.manualControl[overrideIndex].groups[groupIndex] end,
                set = function(info, value) Private.db.profile.manualControl[overrideIndex].groups[groupIndex] = value end,
                disabled = function() return Private.db.profile.manualControl[overrideIndex].groupStyle == 1 or not Private.db.profile.manualControl[overrideIndex].enabled end,
                width = 0.75,
                order = groupIndex + 5
            }
        end

        root.args.overrideContainer.args["override"..overrideIndex] = overrideGroup
    end

    return root
end
