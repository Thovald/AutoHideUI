do
    local _, Private = ...

    local type = "AutoHideUI_ToggleExpand"
    local version = 1
    local texTable = {
        method = "SetAtlas",
        unchecked = "common-button-collapseExpand-down",
        checked   = "common-button-collapseExpand-up",
        pushedOff = "common-button-collapseExpand-down-pressed",
        pushedOn  = "common-button-collapseExpand-up-pressed",
        highlight = "common-button-collapseExpand-hover",
    }

    Private.AceWidgetTemplates:RegisterToggleWidget(type, version, texTable, 30, 30)
end