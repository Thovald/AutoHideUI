local _, Private = ...
local Config = Private.Config
local Changelog = Private.Changelog
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local CHANGELOG_DATA = {
    {
        version = "1.2.0",
        date = "May 15th",
        entries = {
            {
                title = "Conditions",
                comment = "Please have a look at your settings for the Conditions 'Instance', 'Target' and 'Focus' to check if your old settings have been converted correctly.",
                content =  {
                    "Some Conditions have been converted to a new type of grouped Condition.|n"..
                    "The head of the group (parent) controls the settings of the group contents (children).|n"..
                    "The user can toggle and override the settings of each child individually.",

                    "'Instance' Condition has been converted to a grouped Condition.",

                    "New Dungeon, Raid, Battleground, Arena, Scenario and Neighborhood Conditions have been added as children to the 'Instance' Condition.",

                    "'Housing' Condition is now a child of the 'Instance' Condition and has been split up into 'Neighborhood' and 'Housing'.",

                    "'Target' Condition is now a grouped Condition and no longer includes focus targeting.",

                    "New grouped Condition 'Focus' to handle focus targeting",
                },
            },
            {
                title = "Misc",
                content =  {
                    "Added 'Changelog' Button.",

                    "The name of the currently selected group is now shown more prominently at the top.",

                    "Replaced the 'Priority Condition' checkbox with a more compact icon.",

                    "Improved version control to repair or convert user settings on major updates.",

                },
            },
            {
                title = "Fixes",
                content =  {
                    "Fixed EllesmereUI's Minimap not being recognized anymore.",

                    "Fixed a bug where a Group with no Frames selected could break the fade for other Groups."
                
                },
            },
        },
    },

}

-- ============================================================================
-- Main Window
-- ============================================================================

local changelogFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
Changelog.frame = changelogFrame
changelogFrame:SetSize(700, 500)
changelogFrame:SetPoint("TOPRIGHT")
changelogFrame:SetMovable(true)
changelogFrame:EnableMouse(true)
changelogFrame:RegisterForDrag("LeftButton")
changelogFrame:SetScript("OnDragStart", changelogFrame.StartMoving)
changelogFrame:SetScript("OnDragStop", changelogFrame.StopMovingOrSizing)

changelogFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 32,
    insets = {
        left = 8,
        right = 8,
        top = 8,
        bottom = 8,
    },
})
changelogFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)

changelogFrame:Hide()

-- Title
local frameTitle = changelogFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frameTitle:SetPoint("TOP", 0, -16)
frameTitle:SetText("Changelog - Auto Hide UI")

-- Close
local closeButton = CreateFrame("Button", nil, changelogFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -6, -6)

-- ============================================================================
-- Scroll Area
-- ============================================================================

local scrollFrame = CreateFrame("ScrollFrame", nil, changelogFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 16, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 16)

local contentFrame = CreateFrame("Frame", nil, scrollFrame)
contentFrame:SetSize(1, 1)

scrollFrame:SetScrollChild(contentFrame)

-- ============================================================================
-- Helper
-- ============================================================================

local currentYOffset = -10
local contentWidth = 620

local function AddLine(text, fontObject, indent, color, heightMultiplier)
    local fs = contentFrame:CreateFontString(nil, "OVERLAY", fontObject or "GameFontHighlight")

    fs:SetWidth(contentWidth - indent)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")

    fs:SetPoint("TOPLEFT", indent, currentYOffset)

    if color then
        fs:SetText(color .. text .. "|r")
    else
        fs:SetText(text)
    end

    if heightMultiplier then
        local height = fs:GetFontHeight() * heightMultiplier
        fs:SetFontHeight(height)
    end

    currentYOffset = currentYOffset - fs:GetStringHeight() - 6

    return fs
end

local function AddBullet(text)
    local bulletFrame = CreateFrame("Frame", nil, contentFrame)
    bulletFrame:SetPoint("TOPLEFT", 10, currentYOffset)
    bulletFrame:SetSize(contentWidth - 10, 1)

    -- Bullet
    local bullet = bulletFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bullet:SetPoint("TOPLEFT", 0, 0)
    bullet:SetText("•")

    -- Text
    local fs = bulletFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetWidth(contentWidth - 30)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetPoint("TOPLEFT", 14, 0)

    fs:SetText(text)

    local height = math.max(fs:GetStringHeight(), 12)

    bulletFrame:SetHeight(height)

    currentYOffset = currentYOffset - height - 6
end

local function AddSeparator()
    local line = contentFrame:CreateTexture(nil, "ARTWORK")

    --line:SetColorTexture(1, 1, 1, 0.15)
    line:SetAtlas("RecipeList-Divider")

    line:SetHeight(3)
    line:SetWidth(contentWidth - 20)

    line:SetPoint("TOPLEFT", 10, currentYOffset)

    currentYOffset = currentYOffset - 14
end

-- ============================================================================
-- Build Changelog
-- ============================================================================

for _, versionData in ipairs(CHANGELOG_DATA) do

    -- Version Header
    AddLine(
        string.format("Version %s - %s", versionData.version, versionData.date),
        "GameFontNormalLarge",
        10,
        "|cffFFD100",
        0.9
    )

    currentYOffset = currentYOffset - 4

    for _, entry in ipairs(versionData.entries) do

        -- Category Title
        if entry.title then
            AddLine(
                entry.title..":",
                "GameFontNormal",
                10,
                "|cffFFD100"
            )
        end

        -- Comment
        if entry.comment then
            AddLine(
                entry.comment,
                "GameFontDisable",
                10,
                "|cffFFEB89"
            )
        end

        -- Bullet Entries
        if entry.content then
            for _, bulletText in ipairs(entry.content) do
                AddBullet(bulletText)
            end
        end

        currentYOffset = currentYOffset - 10
    end

    AddSeparator()
    currentYOffset = currentYOffset - 10
end

contentFrame:SetSize(contentWidth, math.abs(currentYOffset) + 20)


-- ============================================================================
-- Options button
-- ============================================================================

local changelogButton = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
changelogButton:SetSize(140, 24)
changelogButton:SetFrameStrata("MEDIUM")
changelogButton:SetText(L["buttonChangelog"])

function Changelog.ShowButton(anchorFrame)
    changelogButton.optionsFrame = anchorFrame
    changelogButton:Show()
    changelogButton:SetParent(anchorFrame)
    changelogButton:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", -5, 5)

    if not changelogFrame:IsShown() then
        changelogFrame:SetParent(changelogButton)
        changelogFrame:ClearAllPoints()
        changelogFrame:SetPoint("TOPRIGHT", changelogButton, "TOPRIGHT", 0,0)
        changelogFrame:SetFrameStrata("HIGH")
        changelogFrame:SetFrameLevel(50)
    end
end

function Changelog.HideButton()
    changelogButton:Hide()
end

changelogButton:SetScript("OnClick", function(self)
    changelogFrame:SetShown(not changelogFrame:IsShown())
end)