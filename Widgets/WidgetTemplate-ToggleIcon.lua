local _, Private = ...
Private.AceWidgetTemplates = {}

local AceGUI = LibStub("AceGUI-3.0")
 
-- ─────────────────────────────────────────────────────────────────────────────
-- Visual helpers
-- ─────────────────────────────────────────────────────────────────────────────
 
local function UpdateIcon(self)
    if not self.icon then return end
    --self.text:Hide()
    local tex = self.textures or {}
    local method = tex.method or "SetTexture"
    if self.checked == true then
        self.icon[method](self.icon, tex.checked   or tex.unchecked)
        --self.icon:SetDesaturated(false)
    elseif self.checked == nil then
        -- Tristate / indeterminate: use dedicated texture if provided,
        -- otherwise fall back to unchecked.
        self.icon[method](self.icon, tex.tristate or tex.unchecked)
        --self.icon:SetDesaturated(true)
    else
        self.icon[method](self.icon, tex.unchecked or tex.checked)
        --self.icon:SetDesaturated(true)
    end
    -- Suppress the base checkbox's own checkmark, which _baseSetValue
    -- re-shows whenever the value is true.
    self.check:Hide()
end
 
-- ─────────────────────────────────────────────────────────────────────────────
-- Additional frame scripts (bolted on top of the base CheckBox scripts)
-- ─────────────────────────────────────────────────────────────────────────────
 
local function OnEnter(frame)
    local self = frame.obj
    if self.iconHighlight then self.iconHighlight:Show() end
    if frame._baseOnEnter then frame._baseOnEnter(frame) end
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
    if frame._baseOnLeave then frame._baseOnLeave(frame) end
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
    if frame._baseOnMouseDown then frame._baseOnMouseDown(frame) end
end
 
local function OnMouseUp(frame)
    local self = frame.obj
    if not self.disabled then
        self.icon:SetVertexColor(1, 1, 1)
    end
    UpdateIcon(self)
    if frame._baseOnMouseUp then frame._baseOnMouseUp(frame) end
end
 
local function OnClick(frame)
    local self = frame.obj
    if not self.disabled then
        local newVal
        if self.tristate then
            -- Cycle: false -> true -> nil -> false -> ...
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
 
--- Override SetValue so the icon updates whenever the value changes.
-- The base method still runs to keep tri-state and internal state correct.
local function SetValue(self, val)
    self.checked = val and true or false
    self._baseSetValue(self, val)   -- keeps the base widget's internal state in sync
    UpdateIcon(self)
end

--- Override OnRelease to clean up our custom visuals before the widget
--- is returned to the pool.
local function OnRelease(self)
    if self._baseOnRelease then self._baseOnRelease(self) end
    --self.textures = nil
    self.icon:SetVertexColor(1, 1, 1)
    --self.icon:SetTexture(nil)
    self.iconHighlight:Hide()
end
 
--- Override SetDisabled to darken the icon when not interactable.
local function SetDisabled(self, disabled)
    self._baseSetDisabled(self, disabled)
    if disabled then
        self.icon:SetVertexColor(0.5, 0.5, 0.5)
    else
        self.icon:SetVertexColor(1, 1, 1)
    end
end
 
--- Assign textures. Safe to call at any time.
local function SetTextures(self, tbl)
    self.textures = tbl
    local method = tbl.method or "SetTexture"
 
    if tbl.highlight then
        if not self.iconHighlight then
            -- HIGHLIGHT layer sits above ARTWORK so it always shows on top.
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
-- Constructor
-- ─────────────────────────────────────────────────────────────────────────────
 
local function GetConstructor(texTable, type, width, height)
    return function()
        -- 1. Build a complete, fully-wired CheckBox widget.
        local baseConstructor = AceGUI.WidgetRegistry["CheckBox"]
        local widget = baseConstructor()
    
        -- 2. Hide the standard checkbox textures (checkbg, check, highlight).
        --    They still exist on the frame; we just don't want them visible.
        widget.checkbg:Hide()
        widget.check:Hide()
        widget.highlight:Hide()   -- the base checkbox's own highlight texture
    
        -- 3. Add our replacement icon on the ARTWORK layer, occupying the same
        --    space the original checkbox graphic used (left-hand side of the frame).
        local icon = widget.frame:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(width or 24)
        icon:SetHeight(height or 24)
        icon:SetPoint("LEFT", widget.frame, "LEFT", 1, 0)
        widget.icon = icon
    
        -- 4. Stash the base method/script references before we override them.
        widget._baseSetValue    = widget.SetValue
        widget._baseSetDisabled = widget.SetDisabled
        widget._baseOnRelease   = widget.OnRelease
        widget._baseOnEnter     = widget.frame:GetScript("OnEnter")
        widget._baseOnLeave     = widget.frame:GetScript("OnLeave")
        widget._baseOnMouseDown = widget.frame:GetScript("OnMouseDown")
        widget._baseOnMouseUp   = widget.frame:GetScript("OnMouseUp")
    
        -- 5. Wire in our new scripts (they call the base ones internally).
        widget.frame:SetScript("OnClick",     OnClick)
        widget.frame:SetScript("OnEnter",     OnEnter)
        widget.frame:SetScript("OnLeave",     OnLeave)
        widget.frame:SetScript("OnMouseDown", OnMouseDown)
        widget.frame:SetScript("OnMouseUp",   OnMouseUp)
    
        -- 6. Attach our extra methods.
        widget.SetValue     = SetValue
        widget.SetTextures  = SetTextures
        widget.SetDisabled  = SetDisabled
        widget.OnRelease    = OnRelease
    
        -- 7. Rename so AceGUI tracks it as our type.
        widget.type = type
    
        -- 8. Placeholder textures using built-in WoW assets so the widget is
        --    immediately visible for testing. Replace with your own textures via
        --    widget:SetTextures({...}) once you have them ready.
        widget:SetTextures(texTable)
    
        widget.text:Hide()
        return AceGUI:RegisterAsWidget(widget)
    end
end

Private.AceWidgetTemplates.RegisterToggleWidget = function(self, type, version, texTable, width, height)
    local constructor = GetConstructor(texTable, type, width, height)
    AceGUI:RegisterWidgetType(type, constructor, version)
end
