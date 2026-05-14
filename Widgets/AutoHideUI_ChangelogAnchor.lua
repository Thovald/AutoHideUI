do
    local _, Private = ...
    local AceGUI = LibStub("AceGUI-3.0")

    local Type = "AutoHideUI_ChangelogButtonAnchor"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetHeight(1)
        local widget = {
            type = Type,
            frame = frame,
        }

        -- required
        function widget:SetText(text)
        end

        function widget:SetFontObject(...)
        end

        function widget:OnAcquire()
            self.frame:Show()
            Private.Changelog.ShowButton(self.frame)
        end

        function widget:OnRelease()
            self.frame:Hide()
            Private.Changelog:HideButton()
        end

        return AceGUI:RegisterAsWidget(widget)
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)

end