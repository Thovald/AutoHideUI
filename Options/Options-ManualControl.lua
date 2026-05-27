local _, Private = ...
local Main = Private.Main
local Config = Private.Config
local Fading = Private.Fading
local ManualControl = Private.ManualControl
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local capturingKeybind = false
local activeKeybinds = {}
local activeMacros = {}
local activeOverrides = {}
local GetCurrentKeyBoardFocus, IsControlKeyDown, IsShiftKeyDown, IsAltKeyDown
    = GetCurrentKeyBoardFocus, IsControlKeyDown, IsShiftKeyDown, IsAltKeyDown

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Data
-- ─────────────────────────────────────────────────────────────────────────────

local MANUAL_CONTROL_DEFAULTS = {
    enabled = true,
    printMessage = false,
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
            width = 0.6,
            order = 5,
            get = function(info) return Private.db.profile.manualControl[info.arg.index].enabled end,
            set = function(info, value) Private.db.profile.manualControl[info.arg.index].enabled = value end,
            arg = {},
        },
        spacerEnable = {
            type = "description",
            name = " ",
            width = 0.1,
            order = 6,
        },
        togglePrint = {
            type = "toggle",
            name = L["checkbox_printOverride"],
            desc = L["description_printOverride"],
            disabled = function(info) return not Private.db.profile.manualControl[info.arg.index].enabled end,
            width = 0.8,
            order = 7,
            get = function(info) return Private.db.profile.manualControl[info.arg.index].printMessage end,
            set = function(info, value) Private.db.profile.manualControl[info.arg.index].printMessage = value end,
            arg = {},
        },
        spacerPrint = {
            type = "description",
            name = " ",
            width = 0.1,
            order = 8,
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
                local capturingText = capturingKeybind and info.arg.buttonIsCapturing and L["button_setHotkeyRecording"]
                local keybindText = Private.db.profile.manualControl[info.arg.index].keybindDisplay ~= "" and Private.db.profile.manualControl[info.arg.index].keybindDisplay
                return capturingText or keybindText or L["button_setHotkey"]
            end,
            desc = L["description_setHotkey"],
            disabled = function(info) return not Private.db.profile.manualControl[info.arg.index].enabled end,
            type = "execute",
            width = 0.9,
            func = function(info)
                capturingKeybind = true
                info.arg.buttonIsCapturing = true
                ManualControl.RecordKeybind(info.arg.index, info.arg)
            end,
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
            set = function(info, value)
                local macroString = value:gsub("%s+", "") -- removing spaces
                ManualControl.UpdateActiveKeybindsAndMacros()
                ManualControl.CheckForDuplicateMacros(Private.db.profile.manualControl[info.arg.index], macroString)
                Private.db.profile.manualControl[info.arg.index].macro = macroString
            end,
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
}

local DISPLAY_NAMES = {
    MiddleButton = L["mouseMiddle"],
    Button4 = L["mouseBtn4"],
    Button5 = L["mouseBtn5"],

    NUMPADPLUS = L["num+"],
    NUMPADMINUS = L["num-"],

    PAGEUP = L["pageUp"],
    PAGEDOWN = L["pageDown"],
}

do
    -- using two frames to capture and listen to keybinds.
    -- because switching SetPopagate on the fly during keybinding doesn't intercept key presses.
    -- could use one frame and change the state on options open/close, but combat may prevent it. 

    -- capturing
    local captureFrame = CreateFrame("Frame", nil, UIParent)

    captureFrame:EnableKeyboard(true)
    captureFrame:EnableMouse(true)
    captureFrame:SetPropagateKeyboardInput(false)
    captureFrame:SetPropagateMouseClicks(false)
    captureFrame:SetFrameStrata("TOOLTIP")
    captureFrame:SetAllPoints(UIParent)
    captureFrame:Hide()

    captureFrame:SetScript("OnKeyDown", function(_, key)
        ManualControl.StartCapture(key)
    end)

    captureFrame:SetScript("OnMouseDown", function(_, button)
        ManualControl.StartCapture(button)
    end)

        -- listening
    local listenerFrame = CreateFrame("Frame", nil, UIParent)

    listenerFrame:EnableKeyboard(true)
    listenerFrame:EnableMouse(true)
    listenerFrame:EnableMouseWheel(true)
    listenerFrame:SetPropagateKeyboardInput(true)
    listenerFrame:SetPropagateMouseClicks(true)
    listenerFrame:SetPropagateMouseMotion(true)
    listenerFrame:SetFrameStrata("DIALOG")
    listenerFrame:SetAllPoints(UIParent)
    listenerFrame:Hide()

    listenerFrame:SetScript("OnKeyDown", function(_, key)
        ManualControl.OnListenerKeyPress(key)
    end)

    listenerFrame:SetScript("OnMouseDown", function(_, button)
        ManualControl.OnListenerKeyPress(button)
    end)

    ManualControl.captureFrame = captureFrame
    ManualControl.listenerFrame = listenerFrame
end

function ManualControl.RecordKeybind(index, buttonArg)
    ManualControl.captureFrame.db = Private.db.profile.manualControl[index]
    ManualControl.captureFrame.buttonArg = buttonArg
    ManualControl.captureFrame:Show()
    Config.RefreshUI()
end


local function BuildBindingData(key)
    local bindingParts = {}
    local displayParts = {}

    if IsControlKeyDown() then
        table.insert(bindingParts, "CTRL")
        table.insert(displayParts, L["ctrl"])
    end

    if IsShiftKeyDown() then
        table.insert(bindingParts, "SHIFT")
        table.insert(displayParts, L["shift"])
    end

    if IsAltKeyDown() then
        table.insert(bindingParts, "ALT")
        table.insert(displayParts, L["alt"])
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
    ManualControl.UpdateActiveKeybindsAndMacros()
    ManualControl.captureFrame.buttonArg.buttonIsCapturing = false
    ManualControl.captureFrame:Hide()
    Config.RefreshUI()
end

function ManualControl.StartCapture(key)
    if FORBIDDEN_KEYS[key] then
        return
    end

    if key == "ESCAPE" or key == "RightButton" then
        ManualControl.captureFrame.db.keybind = ""
        ManualControl.captureFrame.db.keybindDisplay = ""
        StopCapture()
        return
    end

    local bindData = BuildBindingData(key)

    -- check other overrides for the same keybind and unbind it from them
    local otherOverrideDB = activeKeybinds[bindData.binding] and activeKeybinds[bindData.binding].overrideDB
    if otherOverrideDB and otherOverrideDB ~= ManualControl.captureFrame.db then
        ManualControl.PrintDuplicateAssignmentWarning(L["print_duplicateKeybind"], otherOverrideDB.name, otherOverrideDB.keybindDisplay)
        otherOverrideDB.keybind = ""
        otherOverrideDB.keybindDisplay = ""
    end

    ManualControl.captureFrame.db.keybind = bindData.binding
    ManualControl.captureFrame.db.keybindDisplay = bindData.display

    activeKeybinds[bindData.binding] = ManualControl.captureFrame.db

    StopCapture()
end

function ManualControl.OnListenerKeyPress(key)
    local bindData = BuildBindingData(key)

    if activeKeybinds[bindData.binding] then
        if GetCurrentKeyBoardFocus() then
            return
        end
        ManualControl.ToggleOverride(activeKeybinds[bindData.binding])
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Logic
-- ─────────────────────────────────────────────────────────────────────────────

function ManualControl.AddGroupToAllOverrides()
    for _, overrideInfo in ipairs(Private.db.profile.manualControl) do
        tinsert(overrideInfo.groups, false)
    end
end

function ManualControl.RemoveGroupFromAllOverrides(groupIndex)
    for _, overrideInfo in ipairs(Private.db.profile.manualControl) do
        tremove(overrideInfo.groups, groupIndex)
    end
end

local function CreateOverrideInfo(overrideDB)
    return {
        overrideDB = overrideDB,
        isActive = false
    }
end

function ManualControl.CheckForDuplicateMacros(overrideDB, macroText)
    if not activeMacros[macroText] then
        return
    end

    local otherOverrideDB = activeMacros[macroText].overrideDB
    if otherOverrideDB and otherOverrideDB ~= overrideDB then
        ManualControl.PrintDuplicateAssignmentWarning(L["print_duplicateMacro"], otherOverrideDB.name, otherOverrideDB.macro)
        otherOverrideDB.macro = ""
    end
end

local function PrintOverrideResults(overrideResults, overrideName)
    local groups = {}
    for _, info in ipairs(overrideResults) do
        local groupName = Main.ColorString(info.group.name, info.isEnabled and "green" or "red")
        table.insert(groups, groupName)
    end

    local overrideText = Main.ColorString(L["print_overrideResult"], "blue")
    print(overrideText .. table.concat(groups, ", "))
end

function ManualControl.PrintDuplicateAssignmentWarning(warningText, overrideName, value)
    local title = Main.GetErrorTitleString()
    value = Main.ColorString(value, "red")
    overrideName = Main.ColorString(overrideName, "red")

    print(title .. string.format(warningText, value, overrideName))
end


local function HandleGroupOverride(group, overrideInfo)
    local overrideDB = overrideInfo.overrideDB
    -- this override doesn't affect this group
    if overrideDB.groupStyle == 2 and not overrideDB.groups[group.index] then
        return group.overrideDB and true or false
    end

    Fading.RemoveGroupFromFadeQueue(group)
    Fading.CancelPendingFade(group)

    -- if override is set to all groups then disregard any overrides that may already be active.
    -- this prevents unintuitive situations when user toggles group-specifc overrides while a group-wide one is active.
    if overrideDB.groupStyle == 1 then
        -- flag other overrides as inactive
        for _, otherOverrideInfo in pairs(activeOverrides) do
            if otherOverrideInfo.overrideDB ~= overrideDB then
                otherOverrideInfo.isActive = false
            end
        end

        if overrideInfo.isActive then
            group.overrideDB = overrideDB
            Fading.SetGroupAlpha(group)
            Fading.UpdateAllFrameVisibility()
            return true
        else
            group.overrideDB = nil
            Fading.SetGroupAlpha(group)
            Fading.UpdateAllFrameVisibility()
            return false
        end
    end

    -- disengage previous override
    if group.overrideDB == overrideDB then
        group.overrideDB = nil
        Fading.SetGroupAlpha(group)
        Fading.UpdateAllFrameVisibility()
        return false
    end

    -- apply override
    group.overrideDB = overrideDB
    Fading.SetGroupAlpha(group)
    Fading.UpdateAllFrameVisibility()

    return true
end

function ManualControl.ToggleOverride(overrideInfo)
    local overrideResults = {}
    local overrideDB = overrideInfo.overrideDB
    overrideInfo.isActive = not overrideInfo.isActive

    for _, group in ipairs(Main.activeGroups) do
        local overrideEnabled = HandleGroupOverride(group, overrideInfo)
        tinsert(overrideResults, { group = group, isEnabled = overrideEnabled } )
    end

    if overrideDB.printMessage then
        PrintOverrideResults(overrideResults, overrideDB.name)
    end
end

function ManualControl.DisableAllOverrides()
    for _, group in ipairs(Main.activeGroups) do
        group.overrideDB = nil
    end
end

function ManualControl:HandleMacro(string)
    if activeMacros[string] then
        ManualControl.ToggleOverride(activeMacros[string])
    end
end

function ManualControl.StartListening()
    capturingKeybind = false
    local hasOverrides = ManualControl.UpdateActiveKeybindsAndMacros()
    ManualControl.captureFrame:Hide()

    if hasOverrides then
        ManualControl.listenerFrame:Show()
    else
        ManualControl.listenerFrame:Hide()
    end
end

function ManualControl.StopListening()
    capturingKeybind = false
    ManualControl.listenerFrame:Hide()
end

function ManualControl.UpdateActiveKeybindsAndMacros()
    activeKeybinds = {}
    activeMacros = {}
    activeOverrides = {}
    local foundKeyOrMacro = false

    for _, overrideDB in ipairs(Private.db.profile.manualControl) do
        if overrideDB.enabled then
            local keybind = overrideDB.keybind
            local macro = overrideDB.macro
            local overrideInfo = CreateOverrideInfo(overrideDB)

            tinsert(activeOverrides, overrideInfo)

            if keybind and keybind ~= "" then
                foundKeyOrMacro = true
                activeKeybinds[keybind] = overrideInfo
            end

            if macro and macro ~= "" then
                foundKeyOrMacro = true
                activeMacros[macro] = overrideInfo
            end

        end
    end

    return foundKeyOrMacro
end

function ManualControl.GetNewOverrideEntry(name)
    local newEntry = CopyTable(MANUAL_CONTROL_DEFAULTS)
    newEntry.name = name
    for _, group in ipairs(Private.db.profile.groups) do
        tinsert(newEntry.groups, false)
    end
    return newEntry
end

function ManualControl.ShowCreateDialog()
    StaticPopupDialogs["AUTOHIDEUI_CREATE_ENTITY"].text = L["popup_createOverride"]
    Config.popupContext.editBoxText = L["name_newOverride"]

    Config.popupContext.callbacks.createOnAccept = function(name)
        local newEntry = ManualControl.GetNewOverrideEntry(name)
        tinsert(Private.db.profile.manualControl, newEntry)
    end

    StaticPopup_Show("AUTOHIDEUI_CREATE_ENTITY")
end

function ManualControl.ShowRenameDialog(index)
    StaticPopupDialogs["AUTOHIDEUI_RENAME_ENTITY"].text = L["popup_renameOverride"]
    Config.popupContext.editBoxText = Private.db.profile.manualControl[index].name

    Config.popupContext.callbacks.renameOnAccept = function(name)
        Private.db.profile.manualControl[index].name = name
    end

    StaticPopup_Show("AUTOHIDEUI_RENAME_ENTITY")
end

function ManualControl.ShowDeleteDialog(index)
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

    for overrideIndex, overrideDB in ipairs(Private.db.profile.manualControl) do
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
        overrideGroup.name = overrideDB.name
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
