do
    local _, Private = ...
    local AceGUI = LibStub("AceGUI-3.0")
    AceGUI:RegisterWidgetType("AutoHideUI_ToggleHover", function()
        local widget = AceGUI:Create("CheckBox")

        widget.frame:HookScript("OnEnter", function(self)
            local frameString = self.obj.userdata.option.arg.frameString
            Private.FramesTab.OnHover(frameString, true)
        end)

        widget.frame:HookScript("OnLeave", function(self)
            local frameString = self.obj.userdata.option.arg.frameString
            Private.FramesTab.OnHover(frameString, false)
        end)

        return widget
    end, 1)
end