local _, Private = ...
-- namespaces for functions that are called between files
local Main = Private.Main
local Config = Private.Config
local FrameFinder = Private.FrameFinder
-- namespace for functions that are referenced before they are defined
local internal = {}

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function FrameFinder.Start()
    if Main.blizzFrame and Main.blizzFrame:IsVisible() then
        HideUIPanel(SettingsPanel)
    else
        AceConfigDialog:Close("AutoHideUI")
    end

    RunNextFrame(function()
        Main.SuspendAddon()
        FrameFinder:ShowWindow()
    end)
end

function FrameFinder.ShowWindow()

end
