do
    local _, Private = ...

    local type = "AutoHideUI_ToggleCog"
    local version = 1
    local texTable = {
        method = "SetTexture",
        unchecked = "Interface\\AddOns\\AutoHideUI\\Media\\cog_off.png",
        checked   = "Interface\\AddOns\\AutoHideUI\\Media\\cog_on.png",
        pushedOff = "Interface\\AddOns\\AutoHideUI\\Media\\cog_off_pushed.png",
        pushedOn  = "Interface\\AddOns\\AutoHideUI\\Media\\cog_on_pushed.png",
        highlight = "Interface\\AddOns\\AutoHideUI\\Media\\cog_highlight.png",
    }

    Private.AceWidgetTemplates:RegisterToggleWidget(type, version, texTable)
end