--[[
Template for a checkbox widget with custom textures to appear like a clickable icon.
User provides a table of textures and a name for the widget to create a new one.
]]

local _, Private = ...
Private.AceWidgetTemplates = {}

local AceGUI = LibStub("AceGUI-3.0")

-- ─────────────────────────────────────────────────────────────────────────────
-- Visual helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function UpdateIcon(self)
    if not self.icon then return end
    local tex = self.textures or {}
    local method = tex.method or "SetTexture"
    if self.checked == true then
        self.icon[method](self.icon, tex.checked or tex.unchecked)
        if self.textures.flipWhenToggled then
            self.icon:SetRotation(math.pi)
            self.iconHighlight:SetRotation(math.pi)
        end
    elseif self.checked == nil then
        self.icon[method](self.icon, tex.tristate or tex.unchecked)
    else
        self.icon[method](self.icon, tex.unchecked or tex.checked)
    end
    self.check:Hide()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Frame scripts
-- ─────────────────────────────────────────────────────────────────────────────

local function OnEnter(frame)
    local self = frame.obj
    if self.iconHighlight then self.iconHighlight:Show() end
    local option = self.userdata and self.userdata.option
    if option then
        local desc = type(option.desc) == "function" and option.desc() or option.desc
        local name = type(option.name) == "function" and option.name() or option.name
        if name or (desc and desc ~= "") then
            GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText(name or "", 1, 0.82, 0, 1)
            GameTooltip:AddLine(desc, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end
end

local function OnLeave(frame)
    local self = frame.obj
    if self.iconHighlight then self.iconHighlight:Hide() end
    GameTooltip:Hide()
end

local function OnMouseDown(frame)
    local self = frame.obj
    if not self.disabled then
        local tex = self.textures or {}
        local method = tex.method or "SetTexture"
        if self.checked and tex.pushedOn then
            self.icon[method](self.icon, tex.pushedOn)
        elseif not self.checked and tex.pushedOff then
            self.icon[method](self.icon, tex.pushedOff)
        else
            self.icon:SetVertexColor(0.6, 0.6, 0.6)
        end
    end
end

local function OnMouseUp(frame)
    local self = frame.obj
    if not self.disabled then
        self.icon:SetVertexColor(1, 1, 1)
    end
    UpdateIcon(self)
end

local function OnClick(frame)
    local self = frame.obj
    if not self.disabled then
        local newVal
        if self.tristate then
            if self.checked == false then
                newVal = true
            elseif self.checked == true then
                newVal = nil
            else
                newVal = false
            end
        else
            newVal = not self.checked
        end
        self.checked = newVal
        self._baseSetValue(self, newVal)
        UpdateIcon(self)
        self:Fire("OnValueChanged", newVal)
    end
    AceGUI:ClearFocus()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Method overrides
-- ─────────────────────────────────────────────────────────────────────────────

local function SetValue(self, val)
    self.checked = val and true or false
    self._baseSetValue(self, val)
    UpdateIcon(self)
end

local function SetDisabled(self, disabled)
    self._baseSetDisabled(self, disabled)
    if disabled then
        self.icon:SetVertexColor(0.5, 0.5, 0.5)
    else
        self.icon:SetVertexColor(1, 1, 1)
    end
end

local function OnRelease(self)
    if self._baseOnRelease then self._baseOnRelease(self) end
    self.icon:SetVertexColor(1, 1, 1)
    if self.iconHighlight then self.iconHighlight:Hide() end
end

local function SetTextures(self, tbl)
    self.textures = tbl
    local method = tbl.method or "SetTexture"

    if tbl.highlight then
        if not self.iconHighlight then
            self.iconHighlight = self.frame:CreateTexture(nil, "HIGHLIGHT")
            self.iconHighlight:SetAllPoints(self.icon)
        end
        self.iconHighlight[method](self.iconHighlight, tbl.highlight)
        self.iconHighlight:SetBlendMode("ADD")
        self.iconHighlight:Hide()
    else
        if self.iconHighlight then
            self.iconHighlight[method](self.iconHighlight, nil)
        end
    end

    UpdateIcon(self)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Constructor factory
-- ─────────────────────────────────────────────────────────────────────────────

local function CreateToggleIconWidget(texTable, sizeInfo)
    -- width = width or 24
    -- height = height or 24

    -- base checkbox and hide default visuals
    local baseConstructor = AceGUI.WidgetRegistry["CheckBox"]
    local widget = baseConstructor()
    widget.checkbg:Hide()
    widget.check:Hide()
    widget.highlight:Hide()

    -- resizing widget
    if sizeInfo and sizeInfo.frame then
        if sizeInfo.frame.width then
            widget._baseSetWidth = widget.SetWidth
            widget.SetWidth = function(self, _) self._baseSetWidth(self, sizeInfo.frame.width) end
        end

        if sizeInfo.frame.height then
            widget._baseSetHeight = widget.SetHeight
            widget.SetHeight = function(self, _) self._baseSetHeight(self, sizeInfo.frame.height) end
        end
    end

    -- custom icon
    local icon = widget.frame:CreateTexture(nil, "ARTWORK")
    if sizeInfo and sizeInfo.icon then
        icon:SetPoint("CENTER")

        if sizeInfo.icon.width then
            icon:SetWidth(sizeInfo.icon.width)
        end

        if sizeInfo.icon.height then
            icon:SetHeight(sizeInfo.icon.height)
        end
    else
        icon:SetAllPoints()
    end
    widget.icon = icon

    -- overriding functions
    widget._baseSetValue = widget.SetValue
    widget._baseSetDisabled = widget.SetDisabled
    widget._baseOnRelease = widget.OnRelease
    widget._baseOnAcquire = widget.OnAcquire

    widget.frame:HookScript("OnEnter", OnEnter)
    widget.frame:HookScript("OnLeave", OnLeave)
    widget.frame:HookScript("OnMouseDown", OnMouseDown)
    widget.frame:HookScript("OnMouseUp", OnMouseUp)

    widget.frame:SetScript("OnClick", OnClick)

    widget.SetValue = SetValue
    widget.SetDisabled = SetDisabled
    widget.OnRelease = OnRelease
    widget.SetTextures = SetTextures
    if sizeInfo and sizeInfo.fullWidth then
        widget.width = "fill"
    end

    widget:SetTextures(texTable)
    widget.text:Hide()

    return AceGUI:RegisterAsWidget(widget)
end

Private.AceWidgetTemplates.RegisterToggleWidget = function(self, type, version, texTable, sizeInfo)
    AceGUI:RegisterWidgetType(type, function()
        return CreateToggleIconWidget(texTable, sizeInfo)
    end, version)
end
