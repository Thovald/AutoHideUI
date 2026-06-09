do
    local _, Private = ...

    local type = "AutoHideUI_ToggleStar"
    local version = 1
    local texTable = {
        method = "SetTexture",
        unchecked = "Interface\\AddOns\\AutoHideUI\\Media\\star_off.png",
        checked   = "Interface\\AddOns\\AutoHideUI\\Media\\star_on.png",
        pushedOff = "Interface\\AddOns\\AutoHideUI\\Media\\star_off_pushed.png",
        pushedOn  = "Interface\\AddOns\\AutoHideUI\\Media\\star_on_pushed.png",
        highlight = "Interface\\AddOns\\AutoHideUI\\Media\\star_highlight.png",
    }
    local sizeInfo = {
        icon = {
            width = 25,
            height = 25,
        },
    }
    Private.AceWidgetTemplates:RegisterToggleWidget(type, version, texTable, sizeInfo)
end