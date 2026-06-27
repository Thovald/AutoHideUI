local _, Private = ...
local Config = Private.Config
local Changelog = Private.Changelog
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local CHANGELOG_DATA = {
    {
        version = "1.2.9",
        date = "June 27th",
        entries = {
            {
                title = "Misc",
                content =  {
                    "Added new tab to the ManualControl tab to document all available commands.",
                },
            },
            {
                title = "Fixes",
                content =  {
                    "Fixed EllesmereUI's QuestTracker.",
                },
            },
        },
    },
    {
        version = "1.2.7",
        date = "June 13th",
        entries = {
            {
                title = "Fixes",
                content =  {
                    "Fixed Flying Condition not updating immediately when dismounting mid-air with steady flight.",

                    "Improved frame initialization on first login and after loading screens.|n"..
                    "This should resolve issues with some AddOns loading their frames very late, such as EllesmereUI's DamageMeter.",

                    "Improved method to restore frames to their original state when user disables them for all groups.",
                },
            },
        },
    },
    {
        version = "1.2.5",
        date = "June 9th",
        entries = {
            {
                title = "Misc",
                content =  {
                    'Viewing the Frames-tab can now highlight active Common Frames, Custom Frames and Mouseover Areas of the current Group.',

                    "Added support for EllesmereUI's Party Frames.",

                    'The height of the options menu is now based on the UI scale to better fit all screens.',

                    'Changed the look of the Expand-Widget in the Conditions tab to make its purpose more obvious.',
                },
            },
            {
                title = "Fixes",
                content =  {
                    'Fixed newly created mouseover-areas saving the wrong position if they were never moved after creation.',

                    'Further improved Vehicle Condition to hopefully only fire when player is unable to use their own spells.'
                },
            },
        },
    },
    {
        version = "1.2.4",
        date = "May 31st",
        entries = {
            {
                title = "Fixes",
                content =  {
                    "Fixed druid flight forms not triggering the Flying Condition anymore.",
                },
            },
        },
    },
    {
        version = "1.2.3",
        date = "May 30th",
        entries = {
            {
                title = "Hotkey Changes",
                comment = "Replaced the system that handles Hotkeys with something more robust.|n"..
                "Your existing Overrides will carry over, but some new restrictions apply.",
                content =  {
                    "The previous system could potentially block inputs for other AddOns.|n"..
                    "The new system has no such risk.",

                    "Unlike the previous system, bindings are now exclusive.|n"..
                    "You can't have an Override and something else bound to the same key-combination anymore.",

                    "The Middle Mouse Button is no longer supported, unfortunately.|n"..
                    "Any Override-bindings that were using it will be reset automatically and print a warning in chat.",

                    "Override Hotkeys can't be set or changed during combat anymore.|n"..
                    "The AddOn will block that and try again when combat ends.|n"..
                    "Logging in or reloading during combat should be unaffected."
                },
            },
            {
                title = "New Commands",
                comment = "Added a bunch of commands that can be used in a macro.",
                content =  {
                    '/autohide setProfile NAME|n'..
                    'Switches to the specified profile.',

                    '/autohide toggleProfile NAME1 NAME2|n'..
                    'Switches between the two specified profiles.',

                    '/autohide resetProfile|n'..
                    'Resets current profile to default.',

                    'Lua command: AutoHideUI:SetProfile("NAME")|n'..
                    'Switches to the specified profile. Could be used for automatic switching.'
                },
            },
            {
                title = "Fixes",
                content =  {
                    "Fixed an issue that could allow frames to fade out while the options menu was open.",
                },
            },
        },
    },
    {
        version = "1.2.2",
        date = "May 27th",
        entries = {
            {
                title = "Fixes",
                content =  {
                    "Lowered the hotkey listener's frame strata to reduce likelyhood of it blocking other AddOn Frames from receiving inputs.",
                    
                    "Listener frame is now hidden when there are no keybinds or macros assigned to overrides."
                },
            },
        },
    },
    {
        version = "1.2.0",
        date = "May 24th",
        entries = {
            {
                title = "New - Grouped Conditions",
                comment = "Take a look at the Conditions settings for 'Instance', 'Target' and 'Focus' to check if your old settings have been converted correctly.",
                content =  {
                    "Some Conditions have been converted to a new type of grouped Condition.|n"..
                    "The head of the group (parent) controls the settings of the group contents (children).|n"..
                    "The user can toggle and customize the settings of each child individually.",

                    "'Instance' Condition has been converted to a grouped Condition.",

                    "New Dungeon, Raid, Battleground, Arena, Scenario and Neighborhood Conditions have been added as children to the 'Instance' Condition.",

                    "'Housing' Condition is now a child of the 'Instance' Condition and has been split up into 'Neighborhood' and 'Housing'.",

                    "'Target' Condition is now a grouped Condition and no longer includes focus targeting.",

                    "New grouped Condition 'Focus' to handle focus targeting",
                },
            },
            {
                title = "New - Manual Controls",
                comment = "Control a Group's Alpha with a keybind or macro.",
                content =  {
                    "Create new Overrides in the 'Manual Control' tab.",

                    "Customize each Override's setting for Keybind, Macro, Alpha and which Groups to affect.",

                    "An Override can be toggled with a keybind and/or macro",

                    "While an Override is engaged, conditions for affected Groups are ignored.",

                    "Useful to quickly show/hide Groups of your choice.",
                },
            },
            {
                title = "New - Mouseover Areas",
                comment = "A tool to create custom areas that you can hover over to trigger mouseover events.",
                content =  {
                    "Access it in the Custom Frames section.",

                    "Create new elements and drag /resize them to define an area.",

                    "The Group's mouseover will trigger when hovering over these areas." .. "|n" ..
                    "Hovering over the Group's Frames works as usual.",

                    "Useful for example to get your Group to fade in when your cursor moves to the edges of your screen.",
                },
            },
            {
                title = "Misc",
                content =  {
                    "Added 'Changelog' Button.",

                    "Added new chat command '/autohide reset' to set the active profile back to defaults.",

                    "The name of the currently selected group is now shown more prominently at the top.",

                    "Replaced the 'Priority Condition' checkbox with a more compact icon.",

                    "Improved version control to repair or convert user settings on major updates.",

                    "The Group-delete button will now gray out if there is only one Group remaining."
                },
            },
            {
                title = "Fixes",
                content =  {
                    "Fixed EllesmereUI's Minimap not being recognized anymore.",

                    "Fixed a bug where a Group with no Frames selected could break the fade for other Groups.",
                
                    "Fixed Custom Frames not being recognized if they had spaces in their names.",

                    "Added more restrictions to the Vehicle Condition to stop it from firing when you wouldn't expect it to."
                },
            },
        },
    },

}

-- everything below was mostly written by AI

-- ─────────────────────────────────────────────────────────────────────────────
-- Main Window
-- ─────────────────────────────────────────────────────────────────────────────

local changelogFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
Changelog.frame = changelogFrame
changelogFrame:SetSize(700, 790)
changelogFrame:SetPoint("TOPRIGHT")
changelogFrame:SetMovable(true)
changelogFrame:EnableMouse(true)
changelogFrame:RegisterForDrag("LeftButton")
changelogFrame:SetScript("OnDragStart", changelogFrame.StartMoving)
changelogFrame:SetScript("OnDragStop", changelogFrame.StopMovingOrSizing)

changelogFrame:SetBackdrop({
    bgFile = "interface/chatframe/chatframebackground",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = false,
    tileSize = 16,
    edgeSize = 32,
    insets = {
        left = 8,
        right = 8,
        top = 8,
        bottom = 8,
    },
})
--changelogFrame:SetBackdropColor(0.1, 0.1, 0.1, 1)
changelogFrame:SetBackdropColor(0.08, 0.08, 0.08, 1)


changelogFrame:Hide()

-- Title
local frameTitle = changelogFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frameTitle:SetPoint("TOP", 0, -16)
frameTitle:SetText("Changelog - Auto Hide UI")

-- Close
local closeButton = CreateFrame("Button", nil, changelogFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -6, -6)

-- ─────────────────────────────────────────────────────────────────────────────
-- Scroll Area
-- ─────────────────────────────────────────────────────────────────────────────

local scrollFrame = CreateFrame("ScrollFrame", nil, changelogFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 16, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 16)

local contentFrame = CreateFrame("Frame", nil, scrollFrame)
contentFrame:SetSize(1, 1)

scrollFrame:SetScrollChild(contentFrame)

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper
-- ─────────────────────────────────────────────────────────────────────────────

local currentYOffset = -10
local contentWidth = 655

local function AddLine(text, fontObject, indent, color, heightMultiplier)
    local fs = contentFrame:CreateFontString(nil, "OVERLAY", fontObject or "GameFontHighlight")

    fs:SetWidth(contentWidth - indent)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetPoint("TOPLEFT", indent, currentYOffset)
    fs:SetSpacing(2)

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
    fs:SetSpacing(2)
    --fs:SetVertexColor(0.9, 0.9, 0.9, 1)

    local height = math.max(fs:GetStringHeight(), 12)

    bulletFrame:SetHeight(height)

    currentYOffset = currentYOffset - height - 10
end

local function AddSeparator()
    local line = contentFrame:CreateTexture(nil, "ARTWORK")

    line:SetAtlas("RecipeList-Divider")

    line:SetHeight(3)
    line:SetWidth(contentWidth - 20)

    line:SetPoint("TOPLEFT", 10, currentYOffset)

    currentYOffset = currentYOffset - 14
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Build Changelog
-- ─────────────────────────────────────────────────────────────────────────────

for _, versionData in ipairs(CHANGELOG_DATA) do

    -- Version Header
    AddLine(
        string.format("Version %s - %s", versionData.version, versionData.date),
        "GameFontNormalLarge",
        10,
        "|cffFFD100"
    )

    currentYOffset = currentYOffset - 4

    for _, entry in ipairs(versionData.entries) do

        -- Category Title
        if entry.title then
            AddLine(
                entry.title..":",
                "GameFontNormal",
                10,
                "|cffFFD100",
                1.1
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


-- ─────────────────────────────────────────────────────────────────────────────
-- Options button
-- ─────────────────────────────────────────────────────────────────────────────

local changelogButton = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
changelogButton:SetSize(140, 24)
changelogButton:SetFrameStrata("MEDIUM")
changelogButton:SetText(L["buttonChangelog"])

function Changelog.ShowButton(anchorFrame)
    changelogButton.optionsFrame = anchorFrame
    changelogButton:Show()
    changelogButton:SetParent(anchorFrame)
    changelogButton:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", 0, 5)

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
    local uiScale = UIParent:GetEffectiveScale()
    local t0, t1 = 0.65, 1.0
    local v0, v1 = 790, 555

    local scaledHeight = v0 + (v1 - v0) * ((uiScale - t0) / (t1 - t0))
    changelogFrame:SetHeight(min(max(555, scaledHeight), 790))

    changelogFrame:SetShown(not changelogFrame:IsShown())
end)