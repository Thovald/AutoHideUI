local _, Private = ...
local Main = Private.Main
local Config = Private.Config
local Fading = Private.Fading
local MouseoverAreas = Private.MouseoverAreas
local mrWindow -- reference to the options frame

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

MouseoverAreas.ActiveAreas = {}
local selectedGroup
local MOUSEOVER_FRAME_POOL = {}
local MIN_SIZE = 50
local pi = math.pi

local COLORS = {
    bodySelected = {0.5, 1, 1, 0.3},
    bodyUnselected = {0.5, 1, 1, 0.15},
    borderSelected = {0.5, 1, 1, 1},
    borderUnselected = {0.5, 1, 1, 0.5},
    selected = {1, 1, 1},
    unselected = {0.5, 1, 1},
}

local RESIZE_BUTTON_MAPPING = {
    { point = "BOTTOMRIGHT", name = "br",   rotation = 0,          tex = "resizeCorner"},
    { point = "BOTTOMLEFT",  name = "bl",   rotation = 3 * pi / 2, tex = "resizeCorner"},
    { point = "TOPLEFT",     name = "tl",   rotation = pi,         tex = "resizeCorner"},
    { point = "TOPRIGHT",    name = "tr",   rotation = pi / 2,     tex = "resizeCorner"},
    { point = "BOTTOM",      name = "b",    rotation = pi,         tex = "resizeEdgeH",   anchors = {"BOTTOMLEFT", "BOTTOMRIGHT", "bl", "TOPRIGHT", "TOPLEFT", "br"} },
    { point = "TOP",         name = "t",    rotation = 0,          tex = "resizeEdgeH",   anchors = {"TOPLEFT", "TOPRIGHT", "tl", "BOTTOMRIGHT", "BOTTOMLEFT", "tr"} },
    { point = "LEFT",        name = "l",    rotation = pi,         tex = "resizeEdgeV",   anchors = {"BOTTOMLEFT", "TOPLEFT", "bl", "TOPRIGHT", "BOTTOMRIGHT", "tl"} },
    { point = "RIGHT",       name = "r",    rotation = 0,          tex = "resizeEdgeV",   anchors = {"BOTTOMRIGHT", "TOPRIGHT", "br", "TOPLEFT", "BOTTOMLEFT", "tr"} },
}

------------------
-- Toggle MouseoverAreas Window
------------------

function MouseoverAreas.Start(groupID)
    selectedGroup = groupID
    if not selectedGroup then
        return
    end

    if Main.blizzFrame and Main.blizzFrame:IsVisible() then
        HideUIPanel(SettingsPanel)
    else
        AceConfigDialog:Close("AutoHideUI")
    end

    RunNextFrame(function()
        Main.SuspendAddon()
        MouseoverAreas:ShowWindow()
        MouseoverAreas:ShowMovers()
    end)
end

function MouseoverAreas.ShowWindow()
    if AutoHideUIMouseoverAreasFrame and AutoHideUIMouseoverAreasFrame:IsShown() then
        return
    end

    Config.SetHeaderText(mrWindow, L["mouseoverAreas"])
    mrWindow:Show()
end

function MouseoverAreas.HideWindow()
    MouseoverAreas:HideMovers()
    mrWindow:Hide()
    AceConfigDialog:Open("AutoHideUI")
end

------------------
-- MouseoverArea Frames
------------------

local function HighlightFrame(self, show)
    if show then
        self.bg:SetColorTexture(unpack(COLORS.bodySelected))
        self.border:SetVertexColor(unpack(COLORS.borderSelected))
    else
        self.bg:SetColorTexture(unpack(COLORS.bodyUnselected))
        self.border:SetVertexColor(unpack(COLORS.borderUnselected))
    end
end

local function OnMouseoverAreaClick(self, button)
    if button == "RightButton" then
        MouseoverAreas:DeleteArea(self.root)
    end
end

local function UpdateAreaDB(frame)
    local db = Private.db.profile[selectedGroup].mouseoverAreas[frame.index]

    if not db then
        return
    end

    local w,h = frame:GetSize()
    local point,_,relativePoint,x,y = frame:GetPoint()

    db.width = w
    db.height = h
    db.point = point
    db.relativePoint = relativePoint
    db.xOffset = x
    db.yOffset = y
end

local function AddAreaToDB(frame)
    local db = Private.db.profile[selectedGroup].mouseoverAreas

    local areaData = {
        width = frame:GetWidth(),
        height = frame:GetHeight(),
        point = "CENTER",
        relativePoint = "CENTER",
        xOffset = 0,
        yOffset = 0,
    }

    table.insert(db, areaData)

    return #db
end

local function RemoveAreaFromDB(index)
    local db = Private.db.profile[selectedGroup].mouseoverAreas
    table.remove(db, index)
end

local CreateMouseoverFrame = function()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetClampRectInsets(1, 0, -1, 0) -- necessary offset, else edges don't register for mouseover
    f:SetResizable(true)
    f:SetResizeBounds(MIN_SIZE, MIN_SIZE)

    -- --debug texture
    -- local t = f:CreateTexture()
    -- t:SetColorTexture(1,0,0,0.25)
    -- t:SetAllPoints()

    -- mover frame
    local mover = CreateFrame("Frame", nil, f)
    f.mover = mover
    mover:EnableMouse(true)
    mover.root = f
    mover:SetAllPoints()
    mover:EnableMouseMotion(true)
    mover:SetScript("OnEnter", function(self) HighlightFrame(self, true) end )
    mover:SetScript("OnLeave", function(self) HighlightFrame(self, false) end )
    mover:SetScript("OnMouseDown", function(self, button) OnMouseoverAreaClick(self, button) end)
    -- mover border
    local b = CreateFrame ("Frame", nil, mover, "NamePlateFullBorderTemplate")
    b:SetVertexColor(unpack(COLORS.borderUnselected))
    mover.border = b
    -- mover bg
    local bg = mover:CreateTexture()
    bg:SetColorTexture(unpack(COLORS.bodyUnselected))
    bg:SetAllPoints()
    mover.bg = bg
    -- dragging
    mover:RegisterForDrag("LeftButton")
    mover:SetScript("OnDragStart", function(self)
        self.root:StartMoving()
    end)
    mover:SetScript("OnDragStop", function(self)
        self.root:StopMovingOrSizing()
        UpdateAreaDB(self.root)
    end)

    for _, info in ipairs(RESIZE_BUTTON_MAPPING) do
        local btn = CreateFrame("Button", nil, mover)
        btn.root = f
        if info.anchors then
            local relativeTo1 = mover[info.anchors[3]]
            local relativeTo2 = mover[info.anchors[6]]
            btn:SetPoint(info.anchors[1], relativeTo1, info.anchors[2], 0, 0)
            btn:SetPoint(info.anchors[4], relativeTo2, info.anchors[5], 0, 0)
        else
            btn:SetPoint(info.point)
            btn:SetSize(20,20)
        end
        btn:SetNormalTexture("Interface\\AddOns\\AutoHideUI\\Media\\"..info.tex..".tga")
        btn:SetHighlightTexture("Interface\\AddOns\\AutoHideUI\\Media\\"..info.tex.."_highlight.tga")
        btn:SetPushedTexture("Interface\\AddOns\\AutoHideUI\\Media\\"..info.tex.."_pressed.tga")

        local normalTex = btn:GetNormalTexture()
        normalTex:SetRotation(info.rotation)
        normalTex:SetVertexColor(unpack(COLORS.unselected))

        local highlightTex = btn:GetHighlightTexture()
        highlightTex:SetRotation(info.rotation)
        highlightTex:SetVertexColor(unpack(COLORS.unselected))

        local pushedTex = btn:GetPushedTexture()
        pushedTex:SetRotation(info.rotation)
        pushedTex:SetVertexColor(unpack(COLORS.unselected))

        btn:SetScript("OnMouseDown", function(self)
            self.root:StartSizing(info.point, true)
        end)

        btn:SetScript("OnMouseUp", function(self)
            self.root:StopMovingOrSizing()
            UpdateAreaDB(self.root)
        end)
        mover[info.name] = btn
    end

    f.mover:Hide()
    return f
end

local function GetNextFrame()
    local frame
    for i, f in ipairs(MOUSEOVER_FRAME_POOL) do
        if not f.isInUse then
            frame = f
            break
        end
    end

    if not frame then
        frame = CreateMouseoverFrame()
        tinsert(MOUSEOVER_FRAME_POOL, frame)
    end

    frame.selected = false
    frame.isInUse = true

    return frame
end

local function UpdateAreaIndexes(index)
    for _, frame in ipairs(MOUSEOVER_FRAME_POOL) do
        if frame.isInUse and frame.index > index then
            frame.index = frame.index - 1
        end
    end
end

function MouseoverAreas:CreateNewArea()
    local frame = GetNextFrame()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER")
    frame:SetPointsOffset(0, -200)
    frame:SetSize(200,200)
    frame:Show()
    frame.mover:Show()
    local index = AddAreaToDB(frame)
    frame.index = index
    frame.group = selectedGroup
    tinsert(MouseoverAreas.ActiveAreas, frame)
end

function MouseoverAreas:DeleteArea(frame)
    RemoveAreaFromDB(frame.index)
    frame.isInUse = false
    frame:Hide()
    UpdateAreaIndexes(frame.index)
end

function MouseoverAreas:CreateAreas()
    wipe(MouseoverAreas.ActiveAreas)
    for groupIndex, groupDate in ipairs(Private.db.profile) do
        if groupDate.mouseoverAreas then
             for i, areaData in ipairs(groupDate.mouseoverAreas) do
                local frame = GetNextFrame()
                frame:ClearAllPoints()
                local width = math.max(areaData.width or 200, MIN_SIZE)
                local height = math.max(areaData.height or 200, MIN_SIZE)
                frame:SetSize(width, height)
                frame:SetPoint(areaData.point, UIParent, areaData.relativePoint, areaData.xOffset, areaData.yOffset)
                frame:Show()
                frame.index = i
                frame.group = groupIndex
                -- Update DB with clamped size if it was changed
                if width ~= areaData.width or height ~= areaData.height then
                    UpdateAreaDB(frame)
                end
                tinsert(MouseoverAreas.ActiveAreas, frame)
            end
        end
    end
end

function MouseoverAreas:ClearAreas()
    for _, frame in ipairs(MouseoverAreas.ActiveAreas) do
        frame.isInUse = false
        frame.mover:Hide()
        frame:Hide()
    end
    wipe(MouseoverAreas.ActiveAreas)
end

function MouseoverAreas:ShowMovers()
    for _, frame in ipairs(MouseoverAreas.ActiveAreas) do
        if frame.group == selectedGroup then
            frame.mover:Show()
        end
    end
end

function MouseoverAreas:HideMovers()
    for _, frame in ipairs(MouseoverAreas.ActiveAreas) do
        frame.mover:Hide()
    end
end

------------------
-- MouseoverAreas Window
------------------

do
    local CreateHeader = Config.CreateHeader

    local frame = CreateFrame("Frame", "AutoHideUIMouseoverAreasFrame", UIParent, "BackdropTemplate")
    frame:SetSize(350, 195)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)

    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    frame:SetBackdropColor(0.1,0.1,0.1,0.95)

    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:Hide()

    ------------------
    -- Header
    ------------------
    CreateHeader(frame)

    ------------------
    -- Left Container
    ------------------

    local rightGroup = Config.CreateAceLikeGroup(frame, L["title_howTo"], 310, 90)
    rightGroup:SetPoint("TOPLEFT", 20, -50)

    local description = rightGroup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    description:SetFontHeight(12)
    description:SetPoint("TOPLEFT", 10, -10)
    description:SetPoint("BOTTOMRIGHT", -10, 10)
    description:SetJustifyH("CENTER")
    --description:SetJustifyV("TOP")

    description:SetText(L["ffDescr_howToMouseoverAreas"])

    local createButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    createButton:SetSize(160, 28)
    createButton:SetPoint("BOTTOMLEFT", 20, 20)
    createButton:SetText(L["button_newArea"])

    createButton:SetScript("OnClick", function()
        MouseoverAreas:CreateNewArea()
    end)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 28)
    closeButton:SetPoint("BOTTOMRIGHT", -20, 20)
    closeButton:SetText(L["button_close"])

    closeButton:SetScript("OnClick", function()
        MouseoverAreas:HideWindow()
    end)

    frame:Hide()
    Private.FrameFinder.frame = frame
    mrWindow = frame
end
