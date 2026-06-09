-- a modified description widget. 
-- runs functions whenever its group is shown/hidden.
do
    local AceGUI = LibStub("AceGUI-3.0")
    AceGUI:RegisterWidgetType("AutoHideUI_TabTracker", function()
        local widget = AceGUI:Create("Label")

        widget.frame:HookScript("OnShow", function(self)
            local OnShowFunc = self.obj.userdata.option.arg.onShow
            if OnShowFunc then
                OnShowFunc()
            end
        end)

        widget.frame:HookScript("OnHide", function(self)
            local OnHideFunc = self.obj.userdata.option.arg.onHide
            if OnHideFunc then
                OnHideFunc()
            end
        end)

        return widget
    end, 1)
end