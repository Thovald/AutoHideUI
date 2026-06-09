local _, Private = ...
local Main = Private.Main
local Config = Private.Config
local FramesTab = Private.FramesTab
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local HIGHLIGHT_FRAMES = {
    pool = {},
    active = {}, -- [frameString] = {frames = {}, isHover = false }
}

local HIGHLIGHT_COLORS = {
    common = {0, 1, 0,},
    custom = {1, 1, 0},
    mouseover = {0.5, 1, 1},
    onHover = {1, 1, 1},
    onHoverAdd = 0.3,
    onHoverAlpha = 0.6,
    alphaBody = 0.2,
    alphaBorder = 1,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Data
-- ─────────────────────────────────────────────────────────────────────────────

-- same order as these will appear in the options.
-- "descr" and "divide" are optional.

FramesTab.DEFAULT_FRAMES = {
    -- unitframes
    { frame = "PlayerFrame",                    label = L["Player Frame"],      enabled = true },
    { frame = "TargetFrame",                    label = L["Target Frame"],      enabled = true },
    { frame = "FocusFrame",                     label = L["Focus Frame"],       enabled = false },
    { frame = "PetFrame",                       label = L["Pet Frame"],         enabled = true },
    { frame = "PartyFrame",                     label = L["Party Frame"],       enabled = false },
    { frame = "PlayerCastingBarFrame",          label = L["Player Castbar"],    enabled = false,    divide = true },
    -- actionbars
    { frame = "MainActionBar",                  label = L["ActionBar 1"],       enabled = true,     descr = L["descr_ActionBar1"] },
    { frame = "MultiBarBottomLeft",             label = L["ActionBar 2"],       enabled = true },
    { frame = "MultiBarBottomRight",            label = L["ActionBar 3"],       enabled = true },
    { frame = "MultiBarRight",                  label = L["ActionBar 4"],       enabled = true },
    { frame = "MultiBarLeft",                   label = L["ActionBar 5"],       enabled = true },
    { frame = "MultiBar5",                      label = L["ActionBar 6"],       enabled = true },
    { frame = "MultiBar6",                      label = L["ActionBar 7"],       enabled = true },
    { frame = "MultiBar7",                      label = L["ActionBar 8"],       enabled = true },
    { frame = "StanceBar",                      label = L["Stance Bar"],        enabled = true },
    { frame = "PetActionBar",                   label = L["Pet Bar"],           enabled = true,     divide = true },
    -- CDM
    { frame = "EssentialCooldownViewer",        label = L["CDM Essential"],     enabled = true },
    { frame = "UtilityCooldownViewer",          label = L["CDM Utility"],       enabled = true },
    { frame = "BuffIconCooldownViewer",         label = L["CDM Buffs"],         enabled = true },
    { frame = "BuffBarCooldownViewer",          label = L["CDM Bars"],          enabled = true },
    { frame = "BuffFrame",                      label = L["Buff Frame"],        enabled = false },
    { frame = "DebuffFrame",                    label = L["Debuff Frame"],      enabled = false },
    { frame = "PersonalResourceDisplayFrame",   label = L["Personal Resource"], enabled = true,     divide = true },
    -- other
    { frame = "DamageMeter",                    label = L["Damage Meter"],      enabled = true },
    { frame = "MinimapCluster",                 label = L["Minimap"],           enabled = false ,   descr = L["descr_Minimap"]},
    { frame = "MicroMenu",                      label = L["Micro Menu"],        enabled = false },
    { frame = "ObjectiveTrackerFrame",          label = L["Objectives Frame"],  enabled = false },
    { frame = "MainStatusTrackingBarContainer", label = L["Experience Bar"],    enabled = false },
    { frame = "BagsBar",                        label = L["Bags Bar"],          enabled = true },

}

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Layout
-- ─────────────────────────────────────────────────────────────────────────────

local FRAMES_TAB = {
    name = L["tab_frameSelect"],
    type = "group",
    disabled = Config.NoSelectedGroup,
    args = {
        spacer_frames1 = {
            type = "description",
            name = "",
            fontSize = "small",
            order = 1,
        },
        text_preview = {
            type = "description",
            name = L["Show active Frames:"],
            fontSize = "medium",
            width = 1,
            order = 2
        },
        checkbox_previewCommon = {
            type = "toggle",
            name = "|cFF00FF00"..L["Common"].."|r",
            width = 0.7,
            get = function(info) return Private.db.profile.previewFrames.common end,
            set = function(info, value) Private.db.profile.previewFrames.common = value end,
            order = 3,
        },
        checkbox_previewCustom = {
            type = "toggle",
            name = "|cFFFFFF00"..L["Custom"].."|r",
            width = 0.7,
            get = function(info) return Private.db.profile.previewFrames.custom end,
            set = function(info, value) Private.db.profile.previewFrames.custom = value end,
            order = 4,
        },
        checkbox_previewMouseover = {
            type = "toggle",
            name = "|cFF80FFFF"..L["Mouseover"].."|r",
            width = 0.7,
            get = function(info) return Private.db.profile.previewFrames.mouseover end,
            set = function(info, value) Private.db.profile.previewFrames.mouseover = value end,
            order = 5,
        },
        spacer_frames2 = {
            type = "description",
            name = "",
            fontSize = "medium",
            order = 6,
        },
        group_defaultFrames = {
            name = L["group_defaultFrames"],
            type = "group",
            inline = true,
            order = 7,
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
                    func = function() Private.FrameFinder.Start() end,
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
                    func = function() Private.MouseoverAreas.Start() end,
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
                    get = function(info) return Private.db.profile.groups[Config.selectedGroup].config.customFrames end,
                    set = function(info, value) Private.db.profile.groups[Config.selectedGroup].config.customFrames = value end,
                    multiline = true,
                    order = 5,
                },
            },
        },
        tabVisibleTracker = {
            type = "description",
            name = "",
            dialogControl = "AutoHideUI_TabTracker",
            order = 9999,
            arg = {
                onShow = function() FramesTab.OnTabShow() end,
                onHide = function() FramesTab.OnTabHide() end,
            },
        }
    },
    order = 21,
}

function FramesTab.GetCommonFrames()
    local frameList = {}
    for _, frameInfo in ipairs(FramesTab.DEFAULT_FRAMES) do
        frameList[frameInfo.frame] = frameInfo.enabled
    end
    return frameList
end

local function GetElementForFrameSelection(order, frameInfo)
    local frameString = frameInfo.frame
    local checkbox = {
        name = frameInfo.label,
        type = "toggle",
        get = function(info) return Private.db.profile.groups[Config.selectedGroup].frames[frameString] end,
        set = function(info, value) Private.db.profile.groups[Config.selectedGroup].frames[frameString] = value end,
        disabled = function(info)
            return FramesTab.IsFrameSelectedElsewhere(frameString)
        end,
        dialogControl = "AutoHideUI_ToggleHover",
        desc = frameInfo.description, -- usually nil
        order = order,
        arg = {frameString = frameString},
    }

    return frameInfo.frame, checkbox
end

function FramesTab.CreateOptions()
    local path = FRAMES_TAB.args.group_defaultFrames.args

    local order = 1
    local spacerCount = 1

    for _, frameInfo in ipairs(FramesTab.DEFAULT_FRAMES) do
        local name, checkbox = GetElementForFrameSelection(order, frameInfo)
        path[name] = checkbox
        order = order + 1

        if frameInfo.divide then
            path["space"..spacerCount] = {
                name = "",
                type = "header",
                order = order,
            }
            spacerCount = spacerCount + 1
            order = order + 1
        end
    end

    return FRAMES_TAB
end

function FramesTab.IsFrameSelectedElsewhere(frameString)
    for index, group in pairs(Private.db.profile.groups) do
        if index ~= Config.selectedGroup and group.frames[frameString] then
            return true
        end
    end
    return false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Highlights
-- ─────────────────────────────────────────────────────────────────────────────

local function UpdateActiveHighlightInfo(frame, frameString)
    if not frame then
        return
    end

    local root = HIGHLIGHT_FRAMES.active[frameString]

    if not root then
        HIGHLIGHT_FRAMES.active[frameString] = {
            frames = {},
            isHover = false,
        }

        root = HIGHLIGHT_FRAMES.active[frameString]
    end

    tinsert(root.frames, frame)
end

 function FramesTab.OnTabShow()
    FramesTab.HideAllHighlights()

    -- need to run these to stay synced with user's settings
    Private.Frames.InitFrames()
    Private.MouseoverAreas.ClearAreas()
    Private.MouseoverAreas.CreateAreas()

    for uiFrame, frameInfo in pairs(Main.activeFrames) do
        local type = frameInfo.isCustom and "custom" or "common"
        local isSelected = frameInfo.group.index == Config.selectedGroup and frameInfo.isInUse
        local shouldShow = Private.db.profile.previewFrames[type]
        local hlFrame = FramesTab.SetHighlightFrame(uiFrame, type, shouldShow, isSelected)
        UpdateActiveHighlightInfo(hlFrame, frameInfo.frameString)
    end

    for i, moFrame in ipairs(Private.MouseoverAreas.ActiveAreas) do
        if moFrame.group == Config.selectedGroup then
            local isSelected = true
            local shouldShow = Private.db.profile.previewFrames["mouseover"]
            local hlFrame = FramesTab.SetHighlightFrame(moFrame, "mouseover", shouldShow, isSelected)
            UpdateActiveHighlightInfo(hlFrame, "mouseoverFrame"..i)
        end
    end
end

function FramesTab.OnTabHide()
    FramesTab.HideAllHighlights()
end

local function ToggleHover(frame, show)
    if show then
        local r, g, b = unpack(HIGHLIGHT_COLORS[frame.uiType])
        r, g, b = r + HIGHLIGHT_COLORS.onHoverAdd, g + HIGHLIGHT_COLORS.onHoverAdd, b + HIGHLIGHT_COLORS.onHoverAdd
        frame.texture:SetVertexColor(r, g, b)
        frame.texture:SetAlpha(HIGHLIGHT_COLORS.onHoverAlpha)
        frame.border:SetVertexColor(unpack(HIGHLIGHT_COLORS.onHover))
        frame.text:SetVertexColor(unpack(HIGHLIGHT_COLORS.onHover))
        frame.text:SetDrawLayer("OVERLAY")
    else
        FramesTab.SetHighlightColors(frame)
        frame.text:SetDrawLayer("BACKGROUND")
    end

    FramesTab.SetHighlightVisibility(frame, show)
end

function FramesTab.OnHover(frameString, show)
    local highlightInfo = HIGHLIGHT_FRAMES.active[frameString]

    if not highlightInfo then
        return
    end

    for _, frame in ipairs(highlightInfo.frames) do
        ToggleHover(frame, show)
    end
end

function FramesTab.InitHighlightFrame(frame)
    frame:Hide()

    frame.texture:SetColorTexture(1, 1, 1, 1)
    frame.texture:SetAlpha(1)
    frame.border:SetVertexColor(1,1,1,1)
    frame.text:SetVertexColor(1,1,1,1)

    frame.isAvailable = true
    frame.shouldShow = false
    frame.uiType = ""
    frame.uiIsSelected = false
end

local function CreateHighlightFrame()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("HIGH")

    -- texture
    local texture = frame:CreateTexture()
    texture:SetAllPoints()
    frame.texture = texture

    -- border
    local b = CreateFrame ("Frame", nil, frame, "NamePlateFullBorderTemplate")
    b:SetBorderSizes(2,2,2,2)
    frame.border = b

    -- text
    local text = frame:CreateFontString()
    text:SetFont(GameFontNormal:GetFont(), 20, "THICKOUTLINE")
    text:SetPoint("CENTER", frame, "CENTER")
    frame.text = text
    frame.text:Show()

    FramesTab.InitHighlightFrame(frame)

    tinsert(HIGHLIGHT_FRAMES.pool, frame)

    return frame
end

local function GetNextHighlightFrame()
    local nextFrame

    for _, frame in ipairs(HIGHLIGHT_FRAMES.pool) do
        if frame and frame.isAvailable then
            nextFrame = frame
            break
        end
    end

    nextFrame = nextFrame or CreateHighlightFrame()
    nextFrame.isAvailable = false

    return nextFrame
end

function FramesTab.SetHighlightColors(frame)
    local r, g, b = unpack(HIGHLIGHT_COLORS[frame.uiType])

    frame.texture:SetVertexColor(r, g, b)
    frame.texture:SetAlpha(HIGHLIGHT_COLORS.alphaBody)

    frame.border:SetVertexColor(r, g, b)
    frame.border:SetAlpha(HIGHLIGHT_COLORS.alphaBorder)

    frame.text:SetVertexColor(r, g, b)
end

function FramesTab.SetHighlightVisibility(frame, isHover)
    if isHover or (frame.shouldShow and frame.uiIsSelected) then
        frame:Show()
    else
        frame:Hide()
        return
    end

    if frame.uiIsSelected then
        frame.texture:SetColorTexture(1, 1, 1, 1)
    else
        frame.texture:SetTexture("Interface\\AddOns\\AutoHideUI\\Media\\tex_stripe.png", "REPEAT", "REPEAT")
        frame.texture:SetHorizTile(true)
        frame.texture:SetVertTile(true)
    end
end

function FramesTab.SetHighlightFrame(uiFrame, type, shouldShow, isSelected)
    if Main.helperFrames[uiFrame] and not Main.helperFrames[uiFrame].isAnchor then
        return
    end

    local hlFrame = GetNextHighlightFrame()

    hlFrame.shouldShow = shouldShow
    hlFrame.uiIsSelected = isSelected
    FramesTab.SetHighlightVisibility(hlFrame)

    hlFrame.uiType = type
    FramesTab.SetHighlightColors(hlFrame)

    hlFrame:SetAllPoints(uiFrame)
    hlFrame.text:SetText(uiFrame:GetName() or "")
    Config.CheckTextBounds(hlFrame)

    return hlFrame
end

function FramesTab.HideAllHighlights()
    wipe(HIGHLIGHT_FRAMES.active)

    for _, frame in ipairs(HIGHLIGHT_FRAMES.pool) do
        if not frame.isAvailable then
            FramesTab.InitHighlightFrame(frame)
        end
    end
end
