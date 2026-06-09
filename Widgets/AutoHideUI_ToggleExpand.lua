do
    local _, Private = ...

    local type = "AutoHideUI_ToggleExpand"
    local version = 1

    local texTable = {
        method = "SetTexture",
        unchecked = "Interface\\AddOns\\AutoHideUI\\Media\\expand_off.png",
        checked   = "Interface\\AddOns\\AutoHideUI\\Media\\expand_on.png",
        pushedOff = "Interface\\AddOns\\AutoHideUI\\Media\\expand_off.png",
        pushedOn  = "Interface\\AddOns\\AutoHideUI\\Media\\expand_on.png",
        highlight = "Interface\\AddOns\\AutoHideUI\\Media\\expand_highlight.png",
        flipWhenToggled = true,
    }

    local sizeInfo = {
        frame = {
            --width = 30,
            height = 15,
        },
        -- icon = {
        --     width = 30,
        --     height = 45,
        -- },
        fullWidth = true,
    }

    Private.AceWidgetTemplates:RegisterToggleWidget(type, version, texTable, sizeInfo)
end