local _, Private = ...
local Main = Private.Main
local Config = Private.Config
local Fading = Private.Fading
local FrameFinder = Private.FrameFinder
local ffWindow -- reference to the frame

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local selectedGroup
local HELPER_FRAME_POOL = {}
local VISIBILITY_TICKER -- periodically checks frame visibility to toggle helper frames
local mouseoverFrame
local helperFrameList = {}
local lastVisibility = {}
local ignoredFrames = {}
local SEARCH_DEPTH = 3
local collectedFrames = {}
local uiSurface = UIParent:GetWidth() * UIParent:GetHeight()
-- only needed if we decide to enable clickthrough
local lastClickTime = 0

------------------
-- Toggle Frame Finder
------------------

function FrameFinder.Start(groupID)
    selectedGroup = groupID

    if Main.blizzFrame and Main.blizzFrame:IsVisible() then
        HideUIPanel(SettingsPanel)
    else
        AceConfigDialog:Close("AutoHideUI")
    end

    RunNextFrame(function()
        Main.SuspendAddon()
        FrameFinder:ShowWindow()
    end)
end

function FrameFinder.ShowWindow()
    if AutoHideUIFrameFinderFrame and AutoHideUIFrameFinderFrame:IsShown() then
        return
    end
    FrameFinder.WipeLists()
    Config.SetHeaderText(ffWindow, L["frameFinder"])
    ffWindow:Show()
    FrameFinder:UpdateIgnoredFrames()
    FrameFinder:CollectFrames()
    FrameFinder:UpdateHelperFramesVisibility()
    FrameFinder:StartVisibilityTicker()
end

function FrameFinder.HideWindow()
    FrameFinder:DetachMouseoverFrame()
    FrameFinder:ReleaseAllHelperFrames()
    if VISIBILITY_TICKER then
        VISIBILITY_TICKER:Cancel()
    end
    FrameFinder.WipeLists()
    ffWindow:Hide()
end

function FrameFinder.Cancel()
    FrameFinder.HideWindow()
    AceConfigDialog:Open("AutoHideUI")
end

function FrameFinder.ConfirmSelection()
    -- building new Custom Frames string from selection
    -- preserving user's strings that were not found at all, ie from unloaded addons
    local newString = ""
    local frameStrings = {}
    local userStrings = string.gmatch(Private.db.profile[selectedGroup].config.customFrames, "[^,]+")

    for _, helperFrame in ipairs(helperFrameList) do
        frameStrings[helperFrame.name] = {selected = helperFrame.selected}
        if helperFrame.selected then
            newString = newString..helperFrame.name..", "
        end
    end

    for userString in userStrings do
        userString = userString:gsub("%s", "")
        if userString ~= "" and not frameStrings[userString] then
            newString = newString..userString..", "
        end
    end
    Private.db.profile[selectedGroup].config.customFrames = newString
    FrameFinder:HideWindow()
    AceConfigDialog:Open("AutoHideUI")
end

------------------
-- Helper Frames
------------------

local COLORS = {
    bodySelected = {0, 1, 0, 0.2},
    bodyUnselected = {1, 1, 0, 0.05},
    borderSelected = {0, 1, 0, 1},
    borderUnselected = {1, 1, 0, 0.5},
    selected = {0, 1, 0},
    unselected = {1, 1, 1},
}

local BLACK_LIST = {
    AutoHideUIFrameFinderFrame = {
        ignoreFrame = true,
        ignoreChildren = true,
    },
    TimerTracker = {
        ignoreFrame = true,
        ignoreChildren = false,
    },
    MotionSicknessFrame = {
        ignoreFrame = true,
        ignoreChildren = false,
    },
    ContainerFrameContainer = {
        ignoreFrame = true,
        ignoreChildren = false,
    },
    GlobalFXDialogModelScene = {
        ignoreFrame = true,
        ignoreChildren = false,
    },
    GlobalFXMediumModelScene = {
        ignoreFrame = true,
        ignoreChildren = false,
    },
    GlobalFXBackgroundModelScene = {
        ignoreFrame = true,
        ignoreChildren = false,
    },
    GameTooltip = {
        ignoreFrame = true,
        ignoreChildren = true,
    },
    GameTooltipStatusBar = {
        ignoreFrame = true,
        ignoreChildren = true,
    },
    ElvUIParent = {
        ignoreFrame = true,
        ignoreChildren = false,
    },
    StarCursorMain = {
        ignoreFrame = true,
        ignoreChildren = true,
    },
    EllesmereUICursorFrame = {
        ignoreFrame = true,
        ignoreChildren = true,
    },

}

-- mouseoverFrame
do
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(9999)
    local tex = f:CreateTexture("OVERLAY")
    tex:SetColorTexture(1,1,1,0.2)
    tex:SetBlendMode("ADD")
    tex:SetAllPoints()
    f.texture = tex
    local b = CreateFrame ("Frame", nil, f, "NamePlateFullBorderTemplate")
    b:SetBorderSizes(2,2,2,2)
    b:UpdateSizes()
    b:SetVertexColor(1,1,1,1)
    f.border = b
    local t = f:CreateFontString()
    t:SetFont(GameFontNormal:GetFont(), 35, "THICKOUTLINE")
    t:SetPoint("BOTTOM", f, "TOP")
    f.text = t
    mouseoverFrame = f
    f:Hide()
end

local function UpdateMouseoverColor(helperFrame)
    if helperFrame.selected then
        mouseoverFrame.texture:SetVertexColor(unpack(COLORS.selected))
        mouseoverFrame.border:SetVertexColor(unpack(COLORS.selected))
        mouseoverFrame.text:SetVertexColor(unpack(COLORS.selected))
    else
        mouseoverFrame.texture:SetVertexColor(unpack(COLORS.unselected))
        mouseoverFrame.border:SetVertexColor(unpack(COLORS.unselected))
        mouseoverFrame.text:SetVertexColor(unpack(COLORS.unselected))
    end
end

function FrameFinder.FadeOut(frame)
    local timeToFade = 0.3
    local requiredSteps = Fading.GetRequiredSteps(timeToFade)
    local alphaStep =  -0.75 / requiredSteps
    frame.ahui_fadeInfo = {
        mode = "OUT",
        timeToFade = timeToFade,
        startAlpha = 1,
        endAlpha = 0.25,
        alphaFunc = frame._origSetAlpha or frame.SetAlpha,
        currentAlpha = 1,
        fadeTimer = 0,
        alphaStep = alphaStep,
        finishedFunc = FrameFinder.FadeIn,
        finishedArg1 = frame,
    }
    Fading.AddToFadeQueue(frame)
    Fading.StartFadeScript()
end

function FrameFinder.FadeIn(frame)
    local timeToFade = 0.3
    local requiredSteps = Fading.GetRequiredSteps(timeToFade)
    local alphaStep =  0.75 / requiredSteps
    frame.ahui_fadeInfo = {
        mode = "IN",
        timeToFade = timeToFade,
        startAlpha = 0.25,
        endAlpha = 1,
        alphaFunc = frame._origSetAlpha or frame.SetAlpha,
        currentAlpha = 0.25,
        fadeTimer = 0,
        alphaStep = alphaStep,
        finishedFunc = FrameFinder.FadeOut,
        finishedArg1 = frame,
    }
    Fading.AddToFadeQueue(frame)
    Fading.StartFadeScript()
end

local function StartAnimation(frame)
    if frame then
        FrameFinder.FadeOut(frame)
    end
end

local function StopAnimation(frame)
    if frame then
        Fading.WipeFadeQueue()
        frame.frame:SetAlpha(frame.alpha)
    end
end

local function AttachMouseoverFrame(frame, index)
    index = index or 1
    if mouseoverFrame.frame then
        StopAnimation(mouseoverFrame.frame) -- to prevent weirdness on overlapping frames
    end
    UpdateMouseoverColor(frame)
    mouseoverFrame:Show()
    mouseoverFrame:SetAllPoints(frame)
    mouseoverFrame.frame = frame
    mouseoverFrame.level = frame.level
    mouseoverFrame.text:SetText("#"..index ..": ".. frame.name)
    Config.CheckTextBounds(mouseoverFrame, mouseoverFrame.text)
    StartAnimation(frame.frame)
end

function FrameFinder:DetachMouseoverFrame()
    mouseoverFrame:Hide()
    StopAnimation(mouseoverFrame.frame)
end

local function GetFramesUnderCursor()
    local frames = {}

    for _, frame in ipairs(helperFrameList) do
        if frame:IsMouseOver() then
            table.insert(frames, frame)
        end
    end

    table.sort(frames, function(a, b)
        return a.level < b.level
    end)

    return frames
end

local function HighlightHelperFrameAtCursor(step, frame)
    -- we can't rely on OnLeave to detach the highlight because of propagateMouseMotion.
    -- instead OnLeave and OnEnter trigger this cursor check.
    --
    -- scrolling the mouse wheel cycles through the frames under the cursor.
    -- when entering or leaving a frame we start at a selected frame if one exists.
    local helperFrameStack = GetFramesUnderCursor()

    -- this typically means OnLeave, so we can detach the highlight.
    -- but in some cases the stack returns 0 even when entering a frame.
    -- in that case we use the frame coming from the OnEnter event.
    if #helperFrameStack == 0 then
        if frame then
            AttachMouseoverFrame(frame)
            return
        end
        FrameFinder:DetachMouseoverFrame()
        return
    end

    local currentLevel = mouseoverFrame.level
    local bestFrame, bestDelta
    if not currentLevel then
        currentLevel = helperFrameStack[1].level
        bestFrame = helperFrameStack[1]
    end

    local index = 1
    for i, helperFrame in ipairs(helperFrameStack) do
        if helperFrame.selected and step == 0 then
            index = i
            bestFrame = helperFrame
            break
        end

        local level = helperFrame.level
        local delta = (level - currentLevel) * step

        if delta > 0 and (not bestDelta or delta < bestDelta) then
            index = i
            bestDelta = delta
            bestFrame = helperFrame
        end
    end

    if bestFrame then
        AttachMouseoverFrame(bestFrame, index)
    elseif #helperFrameStack > 0 then
        if step >= 0 then
            index = 1
        else
            index = #helperFrameStack
        end
        AttachMouseoverFrame(helperFrameStack[index], index)
    end
end

local function ShouldCollectFrame(frame)
    local name = frame:GetName()
    local onBlackList = BLACK_LIST[name] or ignoredFrames[name]

    if collectedFrames[frame] or (not name) or (onBlackList and onBlackList.ignoreFrame) then
        return false
    end

    -- causing taint when running GetSize on some of these frames.
    -- only seems to happen on hidden frames.
    if not frame:IsVisible() then
        return true
    end

    local width, height = frame:GetSize()
    local surface = width * height
    if surface < 10 or surface >= uiSurface then
        return false
    else
        return true
    end
end

local function ShouldCollectChildFrames(frame)
    local name = frame:GetName()
    local onBlackList = BLACK_LIST[name] or ignoredFrames[name]
    if onBlackList and onBlackList.ignoreChildren then
        return false
    else
        return true
    end
end

local function IsValidFrame(frame)
    if frame:IsForbidden() or frame:IsAnchoringSecret() or frame:HasAnySecretAspect()
    or frame:IsAnchoringRestricted() or not frame.IsObjectType or not frame:IsObjectType("Frame") then
        return false
    else
        return true
    end
end

local function CollectChildFrames(frame, depth, visited)
    depth = depth or 0
    visited = visited or {}

    if (not frame) or visited[frame] or depth >= SEARCH_DEPTH then
        return
    end

    local children = { frame:GetChildren() }
    visited[frame] = true

    for i, child in ipairs(children) do
        if IsValidFrame(child) then
            if ShouldCollectFrame(child) then
                tinsert(collectedFrames, child)
            end

            if ShouldCollectChildFrames(child) then
                CollectChildFrames(child, depth + 1)
            end
        end
    end
end

function FrameFinder.CollectFrames()
    local children = { UIParent:GetChildren() }

    for _, frame in ipairs(children) do
        if IsValidFrame(frame) then
            if ShouldCollectFrame(frame) then
                tinsert(collectedFrames, frame)
            end

            if ShouldCollectChildFrames(frame) then
                CollectChildFrames(frame)
            end
        end
    end
end

local function SetHelperFrameSelected(frame, val)
    if not val then
        frame.selected = false
        frame.border:SetVertexColor(unpack(COLORS.borderUnselected))
        frame.fg:Hide()
    else
        frame.selected = true
        frame.border:SetVertexColor(unpack(COLORS.borderSelected))
        frame.fg:Show()
    end
end

function ClearAllHelperSelection()
    for _, helperFrame in ipairs(helperFrameList) do
        if helperFrame.selected then
            SetHelperFrameSelected(helperFrame, false)
        end
    end
end

local function OnMouseDown()
    local frame = mouseoverFrame.frame
    local currentTime = GetTime()
    if currentTime == lastClickTime then
        return
    end

    if frame.selected then
        SetHelperFrameSelected(frame, false)
        ffWindow:DeselectEntry(frame.name)
    else
        SetHelperFrameSelected(frame, true)
        ffWindow:SelectEntry(frame.name)
    end

    UpdateMouseoverColor(frame)
    lastClickTime = currentTime
end

local function ToggleHelperFrame(name, val)
    local frame
    for _, f in ipairs(helperFrameList) do
        if f.name == name then
            frame = f
            break
        end
    end

    SetHelperFrameSelected(frame, val)
    UpdateMouseoverColor(frame)
end

local function CreateHelperFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("HIGH")
    local b = CreateFrame ("Frame", nil, f, "NamePlateFullBorderTemplate")
    b:SetVertexColor(unpack(COLORS.borderUnselected))
    f.border = b
    local fg = f:CreateTexture()
    fg:SetColorTexture(unpack(COLORS.bodySelected))
    fg:SetAllPoints()
    fg:Hide()
    f.fg = fg
    local fbg = CreateFrame("Frame", nil, UIParent)
    fbg:SetFrameStrata("BACKGROUND")
    fbg:SetAllPoints(f)
    local bg = fbg:CreateTexture()
    bg:SetColorTexture(unpack(COLORS.bodyUnselected))
    bg:SetAllPoints()
    f.bg = bg
    f:EnableMouseMotion(true)
    --f:SetPropagateMouseClicks(true)
    f:SetPropagateMouseMotion(true)
    f:SetScript("OnEnter", function(self) HighlightHelperFrameAtCursor(0, self) end )
    f:SetScript("OnLeave", function(self) HighlightHelperFrameAtCursor(0) end )
    f:SetScript("OnMouseWheel", function(self, delta) HighlightHelperFrameAtCursor(delta * -1) end) -- inverting delta feels more natural
    f:SetScript("OnMouseDown", OnMouseDown)
    return f
end

local function GetNextHelperFrame()
    local frame
    for i, f in ipairs(HELPER_FRAME_POOL) do
        if not f.isInUse then
            frame = f
            break
        end
    end

    if not frame then
        frame = CreateHelperFrame()
        tinsert(HELPER_FRAME_POOL, frame)
    end

    frame.selected = false
    frame.isInUse = true

    return frame
end

function FrameFinder.WipeLists()
    wipe(collectedFrames)
    wipe(helperFrameList)
    wipe(lastVisibility)
    wipe(ignoredFrames)
    Fading.WipeFadeQueue()
end

local function ReleaseHelperFrame(frame)
    SetHelperFrameSelected(frame, false)
    frame.isInUse = false
    frame:ClearAllPoints()
    frame:Hide()
end

function FrameFinder.ReleaseAllHelperFrames()
    for _, helperFrame in ipairs(HELPER_FRAME_POOL) do
        ReleaseHelperFrame(helperFrame)
        ffWindow:DeleteEntry(helperFrame.name)
    end
end

local function RemoveHelperFrame(frame)
    for i, helperFrame in ipairs(helperFrameList) do
        if helperFrame.frame == frame then
            frame:SetAlpha(1)
            ReleaseHelperFrame(helperFrame)
            tremove(helperFrameList, i)
            ffWindow:DeleteEntry(helperFrame.name)
        end
    end
end

local function CheckVisibility(frame)
    local currentVis = frame:IsVisible()
    local visChanged
    if currentVis ~= lastVisibility[frame] then
        visChanged = true
        lastVisibility[frame] = currentVis
    end
    return currentVis, visChanged
end

local function ShouldShowHelper(frame)
    local isVisible, visibilityChanged = CheckVisibility(frame)
    local shouldShow = isVisible and visibilityChanged and frame:GetPoint()
    return shouldShow, visibilityChanged
end

local function ShowHelperFrame(frame, i)
    local helperFrame = GetNextHelperFrame()
    local name = frame:GetName()
    helperFrame:Show()
    helperFrame:SetFrameLevel(i)
    helperFrame:SetAllPoints(frame, true)
    helperFrame.frame = frame
    helperFrame.level = i
    helperFrame.name = name
    helperFrame.alpha = frame:GetAlpha()
    tinsert(helperFrameList, helperFrame)
    ffWindow:AddEntry(helperFrame.name)
    ffWindow.entries[name].helperFrame = helperFrame
    local frameInfo = Main.activeFrames[frame]
    if frameInfo and frameInfo.isCustom then
        SetHelperFrameSelected(helperFrame, true)
        ffWindow:SelectEntry(name)
    end
end

function FrameFinder.UpdateHelperFramesVisibility()
    local count = 0
    for i, frame in ipairs(collectedFrames) do
        local shouldShow, visibilityChanged = ShouldShowHelper(frame)
        if shouldShow then
            count = count + 1
            ShowHelperFrame(frame, i)
        elseif visibilityChanged then
            RemoveHelperFrame(frame)
        end
    end
end

function FrameFinder.UpdateIgnoredFrames()
    for frame, frameInfo in pairs(Main.activeFrames) do
        local isInSelectedGroup = frameInfo.group.index == selectedGroup
        local isCustomFrame = frameInfo.isCustom
        if frameInfo.name and (not isCustomFrame or not isInSelectedGroup) then
            ignoredFrames[frameInfo.name] = {
                ignoreFrame = true,
                ignoreChildren = true,
            }
        end
    end
end

function FrameFinder.StartVisibilityTicker()
    if VISIBILITY_TICKER then
        VISIBILITY_TICKER:Cancel()
    end

    VISIBILITY_TICKER = C_Timer.NewTicker(0.25, FrameFinder.UpdateHelperFramesVisibility)
end

------------------
-- FrameFinder Window
------------------
do
    local CreateHeader = Config.CreateHeader

    local frame = CreateFrame("Frame", "AutoHideUIFrameFinderFrame", UIParent, "BackdropTemplate")
    frame:SetSize(590, 300)
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

    local leftGroup = Config.CreateAceLikeGroup(frame, L["ffTitle_available"], 240, 228)
    leftGroup:SetPoint("TOPLEFT", 20, -50)

    local scrollFrame = CreateFrame("ScrollFrame", nil, leftGroup, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 36)

    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(1,1)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild.rows = {}
    scrollChild.rowHeight = 18
    frame.entries = {}

    local clearButton = CreateFrame("Button", nil, leftGroup, "UIPanelButtonTemplate")
    clearButton:SetSize(140, 22)
    clearButton:SetPoint("BOTTOM", 0, 8)
    clearButton:SetText(L["ffButton_clear"])

    clearButton:SetScript("OnClick", function()
        frame:ClearSelections()
    end)

    ------------------
    -- Right Container
    ------------------

    local rightGroup = Config.CreateAceLikeGroup(frame, L["title_howTo"], 290, 190)
    rightGroup:SetPoint("TOPLEFT", leftGroup, "TOPRIGHT", 20, 0)


    local description = rightGroup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    description:SetFontHeight(12)
    description:SetPoint("TOPLEFT", 10, -10)
    description:SetPoint("BOTTOMRIGHT", -10, 10)
    description:SetJustifyH("CENTER")
    --description:SetJustifyV("TOP")

    description:SetText(L["ffDescr_howTo"])

    local confirmButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    confirmButton:SetSize(140, 28)
    confirmButton:SetPoint("BOTTOMRIGHT", -170, 20)
    confirmButton:SetText(L["ffButton_confirm"])

    confirmButton:SetScript("OnClick", function()
        FrameFinder:ConfirmSelection()
    end)

    local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelButton:SetSize(140, 28)
    cancelButton:SetPoint("LEFT", confirmButton, "RIGHT", 10, 0)
    cancelButton:SetText(L["ffButton_cancel"])

    cancelButton:SetScript("OnClick", function()
        FrameFinder:Cancel()
    end)

    ------------------
    -- Button Logic
    ------------------

    local function CreateRow()
        local row = CreateFrame("Button", nil, scrollChild)
        row:SetHeight(scrollChild.rowHeight)
        row:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
        row:SetWidth(scrollFrame:GetWidth() - 24)

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.text:SetPoint("LEFT", 4, 0)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0.3, 0.3, 0.3, 0.2)
        row.bg:Hide()

        row:SetScript("OnEnter", function(self)
            local helperFrame = ffWindow.entries[self.key].helperFrame
            if helperFrame then
                AttachMouseoverFrame(helperFrame)
            end
            if not self.selected then
                self.bg:Show()
            end
        end)

        row:SetScript("OnLeave", function(self)
            FrameFinder:DetachMouseoverFrame()
            if not self.selected then
                self.bg:Hide()
            end
        end)

        row:SetScript("OnClick", function(self)
            frame:ToggleEntry(self.key)
        end)

        return row
    end

    local function SortEntries()

        local keys = {}

        for k in pairs(frame.entries) do
            table.insert(keys, k)
        end

        table.sort(keys, function(a,b)
            -- sort alphabetically. selected entries always on top.

            local A = frame.entries[a]
            local B = frame.entries[b]

            if A.selected ~= B.selected then
                return A.selected
            end

            return a < b
        end)

        return keys
    end

    local function RefreshList()

        local order = SortEntries()
        local prev

        for i, key in ipairs(order) do

            local row = scrollChild.rows[i]

            if not row then
                row = CreateRow()
                scrollChild.rows[i] = row
            end

            local entry = frame.entries[key]

            row.key = key
            row.selected = entry.selected
            row.text:SetText(key)

            if not prev then
                row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, -4)
            else
                row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -2)
            end

            if entry.selected then
                row.text:SetTextColor(0.3, 1, 0.3)
                row.bg:Show()
            else
                row.text:SetTextColor(1,1,1)
                row.bg:Hide()
            end

            row:Show()

            prev = row
        end

        -- hide unused rows
        for i = #order + 1, #scrollChild.rows do
            scrollChild.rows[i]:Hide()
        end

        scrollChild:SetHeight(#order * (scrollChild.rowHeight + 2) + 10)
    end

    function frame:AddEntry(name)
        frame.entries[name] = { selected = false }
        RefreshList()
    end

    function frame:DeleteEntry(name)
        frame.entries[name] = nil
        RefreshList()
    end

    function frame:SelectEntry(name)
        frame.entries[name].selected = true
        RefreshList()
    end

    function frame:DeselectEntry(name)
        frame.entries[name].selected = false
        RefreshList()
    end

    function frame:ToggleEntry(name)
        local val = not frame.entries[name].selected
        frame.entries[name].selected = val
        ToggleHelperFrame(name, val)
        RefreshList()
    end

    function frame:ClearSelections()
        for k in pairs(frame.entries) do
            frame.entries[k].selected = false
        end
        ClearAllHelperSelection()
        RefreshList()
    end

    frame:Hide()
    Private.FrameFinder.frame = frame
    ffWindow = frame
end
