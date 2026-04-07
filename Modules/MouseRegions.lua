local _, Private = ...
local Main = Private.Main
local Config = Private.Config
local Fading = Private.Fading
local MouseRegions = Private.MouseRegions
local mrWindow -- reference to the frame

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local selectedGroup

------------------
-- Toggle MouseRegions Window
------------------

function MouseRegions.Start(groupID)
    selectedGroup = groupID

    if Main.blizzFrame and Main.blizzFrame:IsVisible() then
        HideUIPanel(SettingsPanel)
    else
        AceConfigDialog:Close("AutoHideUI")
    end

    RunNextFrame(function()
        Main.SuspendAddon()
        MouseRegions:ShowWindow()
    end)
end

function MouseRegions.ShowWindow()
    if AutoHideUIMouseRegionsFrame and AutoHideUIMouseRegionsFrame:IsShown() then
        return
    end

    mrWindow:Show()
end

function MouseRegions.HideWindow()
    mrWindow:Hide()
end


------------------
-- MouseRegions Window
------------------
do
    local frame = CreateFrame("Frame", "AutoHideUIMouseRegionsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(500, 300)
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

    local header = CreateFrame("Frame", nil, frame)
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
    title:SetText("Auto Hide UI - " .. L["mouseRegions"])

    local padding = 20
    local textWidth = title:GetStringWidth()
    header.middle:SetWidth(textWidth + padding)

    ------------------
    -- Left Container
    ------------------

    local leftGroup = Config.CreateAceLikeGroup(frame, L["ffTitle_available"], 220, 228)
    leftGroup:SetPoint("TOPLEFT", 20, -50)

    local scrollFrame = CreateFrame("ScrollFrame", nil, leftGroup, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -36)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 36)

    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(1,1)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild.rows = {}
    scrollChild.rowHeight = 18
    frame.entries = {}

    local createButton = CreateFrame("Button", nil, leftGroup, "UIPanelButtonTemplate")
    createButton:SetSize(100, 28)
    createButton:SetPoint("TOPLEFT", 5, -5)
    createButton:SetText(L["button_create"])

    createButton:SetScript("OnClick", function()
        --FrameFinder:ConfirmSelection()
    end)

    local renameButton = CreateFrame("Button", nil, leftGroup, "UIPanelButtonTemplate")
    renameButton:SetSize(100, 28)
    renameButton:SetPoint("LEFT", createButton, "RIGHT", 10, 0)
    renameButton:SetText(L["button_rename"])

    renameButton:SetScript("OnClick", function()
        --FrameFinder:Cancel()
    end)

    local deleteButton = CreateFrame("Button", nil, leftGroup, "UIPanelButtonTemplate")
    deleteButton:SetSize(100, 28)
    deleteButton:SetPoint("BOTTOM", 0, 5)
    deleteButton:SetText(L["button_delete"])

    renameButton:SetScript("OnClick", function()
        --FrameFinder:Cancel()
    end)

    ------------------
    -- Right Container
    ------------------

    local rightGroup = Config.CreateAceLikeGroup(frame, L["ffTitle_howTo"], 220, 190)
    rightGroup:SetPoint("TOPLEFT", leftGroup, "TOPRIGHT", 20, 0)

    local description = rightGroup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    description:SetFontHeight(12)
    description:SetPoint("TOPLEFT", 10, -10)
    description:SetPoint("BOTTOMRIGHT", -10, 10)
    description:SetJustifyH("CENTER")
    --description:SetJustifyV("TOP")

    description:SetText(L["ffDescr_howTo"])

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 28)
    closeButton:SetPoint("BOTTOMRIGHT", -25, 20)
    closeButton:SetText(L["button_close"])

    closeButton:SetScript("OnClick", function()
        --FrameFinder:ConfirmSelection()
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
            local helperFrame = mrWindow.entries[self.key].helperFrame
            if helperFrame then
                --AttachMouseoverFrame(helperFrame)
            end
            if not self.selected then
                self.bg:Show()
            end
        end)

        row:SetScript("OnLeave", function(self)
            --FrameFinder:DetachMouseoverFrame()
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
        --ToggleHelperFrame(name, val)
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
    mrWindow = frame
end