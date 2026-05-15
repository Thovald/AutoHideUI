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

local function CreateToggleIconWidget(texTable, width, height)
    -- Create base checkbox and hide default visuals
    --local widget = AceGUI:Create("CheckBox")
    local baseConstructor = AceGUI.WidgetRegistry["CheckBox"]
    local widget = baseConstructor()
    widget.checkbg:Hide()
    widget.check:Hide()
    widget.highlight:Hide()

    -- Create custom icon
    local icon = widget.frame:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(width or 24)
    icon:SetHeight(height or 24)
    icon:SetPoint("LEFT", widget.frame, "LEFT", 1, 0)
    widget.icon = icon

    -- Store base methods before overriding
    widget._baseSetValue = widget.SetValue
    widget._baseSetDisabled = widget.SetDisabled
    widget._baseOnRelease = widget.OnRelease

    -- Hook frame scripts (run after base scripts)
    widget.frame:HookScript("OnEnter", OnEnter)
    widget.frame:HookScript("OnLeave", OnLeave)
    widget.frame:HookScript("OnMouseDown", OnMouseDown)
    widget.frame:HookScript("OnMouseUp", OnMouseUp)

    -- Replace OnClick with custom tri-state logic
    widget.frame:SetScript("OnClick", OnClick)

    -- Override methods
    widget.SetValue = SetValue
    widget.SetDisabled = SetDisabled
    widget.OnRelease = OnRelease
    widget.SetTextures = SetTextures

    -- Apply textures
    widget:SetTextures(texTable)
    widget.text:Hide()

    return AceGUI:RegisterAsWidget(widget)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API: Register a new toggle icon widget type
-- ─────────────────────────────────────────────────────────────────────────────

Private.AceWidgetTemplates.RegisterToggleWidget = function(self, type, version, texTable, width, height)
    AceGUI:RegisterWidgetType(type, function()
        return CreateToggleIconWidget(texTable, width, height)
    end, version)
end
