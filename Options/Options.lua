local _, Private = ...
local Main = Private.Main
local Config = Private.Config
local ManualControl = Private.ManualControl
local ConditionsTab = Private.ConditionsTab
local FramesTab = Private.FramesTab

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local pairs, ipairs  = pairs, ipairs

Config.selectedGroup = 1
Config.isOptionsOpen = false
local MENU_WIDTH = 630
local MENU_HEIGHT = 835 -- this is now set on options open, based on ui scale
local MENU_HEIGHT_MIN = 400
local MENU_HEIGHT_MAX = 1000
local UI_WIDTH, UI_HEIGHT = UIParent:GetSize()
local UI_PADDING = 5

Config.popupContext = {
    titleText = "",
    editBoxText = "",
    callbacks = {
        create = function(name) end,
        rename = function(name) end,
        delete = function() end,
    },
    entityID = 1,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Data
-- ─────────────────────────────────────────────────────────────────────────────

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

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Logic
-- ─────────────────────────────────────────────────────────────────────────────

local function IsOtherWindowsShown()
    return AutoHideUIFrameFinderFrame:IsShown() or AutoHideUIMouseoverAreasFrame:IsShown()
end

function Config.PrintOptionsOpenError()
    local title = Main.GetErrorTitleString()
    local message = Main.ColorString(L["error_optionsOpen"], "red")
    print(title..message)
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
        Config.selectedGroup = 1
    elseif Config.selectedGroup and Private.db.profile.groups[Config.selectedGroup] then
        return
    end

    Config.selectedGroup = nil
    for index in ipairs(Private.db.profile.groups) do
        Config.selectedGroup = index
        break
    end
end

function Config.NoSelectedGroup()
    return not Config.selectedGroup
end

function Config.RebuildUI()
    Config.CreateOptionsMenu()
    AceConfigRegistry:NotifyChange("AutoHideUI")
end

function Config.RefreshUI()
    AceConfigRegistry:NotifyChange("AutoHideUI")
end

local function ShowGroupCreateDialog()
    StaticPopupDialogs["AUTOHIDEUI_CREATE_ENTITY"].text = L["popup_createGroup"]
    Config.popupContext.editBoxText = L["name_newGroup"]

    Config.popupContext.callbacks.createOnAccept = function(name)
        tinsert(Private.db.profile.groups, Config.GetNewGroup(name))
        ManualControl.AddGroupToAllOverrides()
        Config.selectedGroup = #Private.db.profile.groups
    end

    StaticPopup_Show("AUTOHIDEUI_CREATE_ENTITY")
end

local function ShowGroupRenameDialog()
    StaticPopupDialogs["AUTOHIDEUI_RENAME_ENTITY"].text = L["popup_renameGroup"]
    Config.popupContext.editBoxText = Private.db.profile.groups[Config.selectedGroup].name

    Config.popupContext.callbacks.renameOnAccept = function(name)
        Private.db.profile.groups[Config.selectedGroup].name = name
    end

    StaticPopup_Show("AUTOHIDEUI_RENAME_ENTITY")
end

local function ShowGroupDeleteDialog()
    StaticPopupDialogs["AUTOHIDEUI_DELETE_ENTITY"].text = L["popup_deleteGroup"]

    Config.popupContext.callbacks.deleteOnShow = function(self)
        if Config.selectedGroup and Private.db.profile.groups[Config.selectedGroup] then
            self:SetText(string.format("%s|n|n-- %s --|n", L["popup_deleteGroup"], Private.db.profile.groups[Config.selectedGroup].name))
        end
    end

    Config.popupContext.callbacks.deleteOnAccept = function()
        if Config.selectedGroup then
            tremove(Private.db.profile.groups, Config.selectedGroup)
            ManualControl.RemoveGroupFromAllOverrides(Config.selectedGroup)
            Config.SetSelectedGroup()
        end
    end

    StaticPopup_Show("AUTOHIDEUI_DELETE_ENTITY")
end

StaticPopupDialogs["AUTOHIDEUI_CREATE_ENTITY"] = {
    text = "",
    button1 = L["button_create"],
    button2 = L["button_cancel"],
    hasEditBox = true,
    timeout = 0,
    whileDead = true,

    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
        self:GetEditBox():SetText(Config.popupContext.editBoxText)
        self:GetEditBox():HighlightText()
    end,

    OnAccept = function(self)
        if not Config.isOptionsOpen then
            Config.PrintOptionsOpenError()
            return
        end

        local newName = self:GetEditBox():GetText()
        if newName and newName ~= "" then
            Config.popupContext.callbacks.createOnAccept(newName)
            Config.RebuildUI()
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
    text = "",
    button1 = L["button_rename"],
    button2 = L["button_cancel"],
    hasEditBox = true,
    timeout = 0,
    whileDead = true,

    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
        self:GetEditBox():SetText(Config.popupContext.editBoxText)
        self:GetEditBox():HighlightText()
    end,

    OnAccept = function(self)
        if not Config.isOptionsOpen then
            Config.PrintOptionsOpenError()
            return
        end

        local newName = self:GetEditBox():GetText()
        if newName and newName ~= "" then
            Config.popupContext.callbacks.renameOnAccept(newName)
            Config.RebuildUI()
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
    text = "",
    button1 = L["button_delete"],
    button2 = L["button_cancel"],
    timeout = 0,
    whileDead = true,

    OnShow = function(self)
        Config.popupContext.callbacks.deleteOnShow(self)
        self:SetFrameStrata("TOOLTIP")
    end,

    OnAccept = function(self)
        if not Config.isOptionsOpen then
            Config.PrintOptionsOpenError()
            return
        end

        Config.popupContext.callbacks.deleteOnAccept()
        Config.RebuildUI()
    end,

    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
}

local function CloseAllPopups()
    StaticPopup_Hide("AUTOHIDEUI_CREATE_ENTITY")
    StaticPopup_Hide("AUTOHIDEUI_RENAME_ENTITY")
    StaticPopup_Hide("AUTOHIDEUI_DELETE_ENTITY")
    Private.Changelog.frame:SetShown(false)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Layout
-- ─────────────────────────────────────────────────────────────────────────────

local OPTIONS_TAB_FADE = {
    name = L["tab_fadeSetup"],
    type = "group",
    disabled = Config.NoSelectedGroup,
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
                    get = function() return Private.db.profile.groups[Config.selectedGroup].config.fadeOutDelay end,
                    set = function(_, value) Private.db.profile.groups[Config.selectedGroup].config.fadeOutDelay = value end,
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
                    get = function() return Private.db.profile.groups[Config.selectedGroup].config.fadeInDelay end,
                    set = function(_, value) Private.db.profile.groups[Config.selectedGroup].config.fadeInDelay = value end,
                    order = 6,
                },
                fadeDuration = {
                    type = "range",
                    name = L["slider_fadeDuration"],
                    width = 1,
                    min = 0,
                    max = 5,
                    softMax = 1,
                    get = function() return Private.db.profile.groups[Config.selectedGroup].config.timeToFade end,
                    set = function(_, value) Private.db.profile.groups[Config.selectedGroup].config.timeToFade = value end,
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
                    width = 1.3,
                    min = 0,
                    max = 1,
                    get = function() return Private.db.profile.groups[Config.selectedGroup].config.idleAlpha end,
                    set = function(_, value) Private.db.profile.groups[Config.selectedGroup].config.idleAlpha = value end,
                    order = 1,
                },
                spacerAlpha = {
                    type = "description",
                    name = " ",
                    width = 0.2,
                    order = 2,
                },
                checkbox_forceAlpha = {
                    type = "toggle",
                    name = L["checkbox_forceAlpha"],
                    desc = L["desc_forceAlpha"],
                    width = 1.3,
                    get = function(info) return Private.db.profile.groups[Config.selectedGroup].config.forceAlpha end,
                    set = function(info, value) Private.db.profile.groups[Config.selectedGroup].config.forceAlpha = value end,
                    order = 3,
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
                    get = function() return Private.db.profile.groups[Config.selectedGroup].config.normalAlphaPref end,
                    set = function(_, value) Private.db.profile.groups[Config.selectedGroup].config.normalAlphaPref = value end,
                    desc = L["tooltip_alphaPref"],
                    order = 6,
                },
                spacerPref = {
                    type = "description",
                    name = " ",
                    width = 0.2,
                    order = 7,
                },
                dropdownPrioAlphaPref = {
                    name = L["dropdown_prioAlphaPref"],
                    type = "select",
                    width = 1.3,
                    values = function() return ALPHA_PREF end,
                    get = function() return Private.db.profile.groups[Config.selectedGroup].config.prioAlphaPref end,
                    set = function(_, value) Private.db.profile.groups[Config.selectedGroup].config.prioAlphaPref = value end,
                    desc = L["tooltip_prioAlphaPref"],
                    order = 8,
                },
            },
        },
    },
    order = 22,
}

Config.OPTIONS_MENU = {
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
                        local groupName = Private.db and Private.db.profile.groups and Private.db.profile.groups[Config.selectedGroup] and Private.db.profile.groups[Config.selectedGroup].name or "?"
                        return L["header_viewingGroup"] .. "|cffffffff" .. groupName .. "|r"
                    end,
                    order = 1,
                },
                groupSelection = {
                    name = L["dropdown_groupSelect"],
                    type = "select",
                    values = function() return GetGroupNames() end,
                    get = function() return Config.selectedGroup end,
                    set = function(_, value) Config.selectedGroup = value end,
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
                    disabled = function() return #Private.db.profile.groups == 1 end,
                    order = 15,
                },
                
            },

        },
        changelogAnchor = {
            type = "description",
            dialogControl = "AutoHideUI_ChangelogButtonAnchor",
            name = "",
            order = 20,
        },
        -- profiles is set later when db has actually been initialized
    },
}



function Config.CreateOptionsMenu()
    UI_WIDTH, UI_HEIGHT = UIParent:GetSize()
    local tabFrames = FramesTab.CreateOptions()
    local tabFade = OPTIONS_TAB_FADE
    local tabConditions = ConditionsTab.CreateOptions()
    local tabManualControl = ManualControl.CreateOptions()

    tabFrames.order = 20
    tabFade.order = 25
    tabConditions.order = 30

    tabManualControl.order = 2

    Config.OPTIONS_MENU.args.setup.args.tabFrames = tabFrames
    Config.OPTIONS_MENU.args.setup.args.tabFade = tabFade
    Config.OPTIONS_MENU.args.setup.args.tabConditions = tabConditions
    Config.OPTIONS_MENU.args.tabManualControl = tabManualControl
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Managing Settings
-- ─────────────────────────────────────────────────────────────────────────────

function Config.ResetProfile()
    Private.db:ResetProfile()
    Main.SuspendAddon()
    Config.SetSelectedGroup()
    Config.RebuildUI()
    Main.ReInitAddon()

    if not AceConfigDialog.OpenFrames["AutoHideUI"] and not IsOtherWindowsShown() then
        AceConfigDialog:Open("AutoHideUI")
    end

    local title = Main.GetErrorTitleString()
    local message = Main.ColorString(L["print_resetSuccess"], "green")
    print(title..message)
end

function Config.SetProfile(newProfile)
    local title = Main.GetErrorTitleString()

    local profileExists = false
    for _, profile in ipairs(Private.db:GetProfiles()) do
        if profile == newProfile then
            profileExists = true
            break
        end
    end

    if not profileExists then
        local message = Main.ColorString(L["print_switchMissing"], "red")
        print(title..message..newProfile)
        return
    elseif Private.db:GetCurrentProfile() == newProfile then
        local message = Main.ColorString(L["print_switchSame"], "red")
        print(title..message..newProfile)
        return
    end

    Main.SuspendAddon()
    Private.db:SetProfile(newProfile)
    Config.SetSelectedGroup()
    Config.RebuildUI()
    Main.ReInitAddon()
    local message = Main.ColorString(L["print_switchSuccess"], "green")
    print(title..message..newProfile)

end

function Config.ToggleProfile(msg)
    local title = Main.GetErrorTitleString()

    local profile1, profile2 = strsplit(" ", msg, 2)
    local profile1Exists, profile2Exists

    if not profile1 or not profile2 then
        print(title..Main.ColorString(L["print_toggleError1"], "red"))
        return
    elseif profile1 == profile2 then
        print(title..Main.ColorString(L["print_toggleError2"], "red"))
        return
    else
        for _, profile in ipairs(Private.db:GetProfiles()) do
            if profile == profile1 then
                profile1Exists = true
            elseif profile == profile2 then
                profile2Exists = true
            end
        end

        if not profile1Exists or not profile2Exists then
            local missingProfiles = (not profile1Exists and profile1 or "") .. (not profile2Exists and (", "..profile2) or "")
            print(title..Main.ColorString(L["print_toggleError3"], "red")..missingProfiles)
            return
        end
    end

    local currentProfile = Private.db:GetCurrentProfile()
    local newProfile = currentProfile == profile1 and profile2 or profile1

    Main.SuspendAddon()
    Private.db:SetProfile(newProfile)
    Config.SetSelectedGroup()
    Config.RebuildUI()
    Main.ReInitAddon()
    local message = Main.ColorString(L["print_switchSuccess"], "green")
    print(title..message..newProfile)
end

function Config.GetNewGroup(name, useDefaultFrameSelection)
    local newGroup = CopyTable(GROUP_TEMPLATE)
    newGroup.frames = FramesTab.GetCommonFrames()
    newGroup.conditions = ConditionsTab.GetDefaultConditions()
    newGroup.name = name

    -- use defaults if no groups exist
    if Config.selectedGroup and not useDefaultFrameSelection then
        for frame in pairs(newGroup.frames) do
            newGroup.frames[frame] = false
        end
    end

    return newGroup
end

function Config.GetDefaultConditionByName(conditionName)
    for _, conditionInfo in ipairs(ConditionsTab.CONDITION_DEFINITIONS) do
        if conditionInfo.name == conditionName then
            return conditionInfo
        end
    end
end

function Config.GetDefaultProfile()
    local defaultProfile = {
        profile = {
            manualControl = {},
            groups = {},
            previewFrames = {
                common = false,
                custom = true,
                mouseover = true,
            },
        }
    }

    return defaultProfile
end

function Config.GetDefaultGroup(name)
    local useDefaultFrameSelection = true
    local defaultGroup = Config.GetNewGroup(name, useDefaultFrameSelection)
    return defaultGroup
end

local function OnOptionsClose()
    if Main.blizzFrame:IsVisible() then
        return
    end

    FramesTab.HideAllHighlights()
    CloseAllPopups()
    Config.isOptionsOpen = false
    Main.ReInitAddon()
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

    Config.isOptionsOpen = true
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
        --f:SetStatusText(L["chatCommands"].." /autohide /autohideui")

        if not frame._isAutoHideHooked then
            frame:SetResizeBounds(MENU_WIDTH, MENU_HEIGHT_MIN, MENU_WIDTH, MENU_HEIGHT_MAX)
            frame:HookScript("OnShow", function() OnOptionsOpen(frame) end)
            frame:HookScript("OnHide", function() OnOptionsClose() end)
            frame._isAutoHideHooked = true
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
    Config.OPTIONS_MENU.args.profiles = AceDBOptions:GetOptionsTable(Private.db)

    AceConfig:RegisterOptionsTable("AutoHideUI", Config.OPTIONS_MENU)
    AceConfigDialog:SetDefaultSize("AutoHideUI", MENU_WIDTH, MENU_HEIGHT)
    Main.blizzFrame = AceConfigDialog:AddToBlizOptions("AutoHideUI", "Auto Hide UI")

    SLASH_AUTOHIDEUI1 = "/autohide"
    SLASH_AUTOHIDEUI2 = "/autohideui"
    SlashCmdList["AUTOHIDEUI"] = function(msg)
        local cmd, arg = strsplit(" ", msg, 2)

        if cmd == "override" then
            ManualControl:HandleMacro(arg)
            return
        elseif cmd == "reset" or cmd == "resetProfile" then
            Config.ResetProfile()
            return
        elseif cmd == "setProfile" then
            Config.SetProfile(arg)
            return
        elseif cmd == "toggleProfile" then
            Config.ToggleProfile(arg)
            return
        end

        if AceConfigDialog.OpenFrames["AutoHideUI"] then
            AceConfigDialog:Close("AutoHideUI")
        elseif not IsOtherWindowsShown() then
            Config.SetOptionsHeight()
            AceConfigDialog:Open("AutoHideUI")
        end
    end

    SetHooksForMenus()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Misc
-- ─────────────────────────────────────────────────────────────────────────────

-- determining default height of options window, based on resolution and ui scale.
-- the optimal height to fit all elements doesn't fit into a 1080p screen at 100% scale.
function Config.SetOptionsHeight()
    local uiScale = UIParent:GetEffectiveScale()
    local t0, t1 = 0.65, 1.0
    local v0, v1 = 835, 600

    local scaledHeight = v0 + (v1 - v0) * ((uiScale - t0) / (t1 - t0))
    MENU_HEIGHT = min(max(MENU_HEIGHT_MIN, scaledHeight), MENU_HEIGHT_MAX)
    AceConfigDialog:SetDefaultSize("AutoHideUI", MENU_WIDTH, MENU_HEIGHT)
end

function Config.SetHeaderText(frame, title)
    frame.header.title:SetText(title .. " - " .. Private.db.profile.groups[Config.selectedGroup].name)
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