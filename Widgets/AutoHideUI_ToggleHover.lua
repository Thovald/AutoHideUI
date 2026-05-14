do
    local _, Private = ...
    local AceGUI = LibStub("AceGUI-3.0")
    AceGUI:RegisterWidgetType("AutoHideUI_ToggleHover", function()
        local widget = AceGUI:Create("CheckBox")

        widget.frame:HookScript("OnEnter", function(self)
            local frameString = self.obj.userdata.option.arg.frameString
            local frameList = Private.Main.FetchFramesFromString(frameString)
            if frameList then
                for _,frame in pairs(frameList) do
                    Private.Config.ShowHighlight(frame)
                end
            end
        end)

        widget.frame:HookScript("OnLeave", function()
            Private.Config.HideAllHighlights()
        end)

        return widget
    end, 1)
end