local _, Private = ...
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local Main = Private.Main
local Migration = Private.Migration
local Config = Private.Config

local DB_SCHEMA_VERSION = 3

local MigrationDB = {
    -- when parent/child conditions were introduced
    [1] = function(profile)
        local OLD_CONDITION_DEFAULTS = {
            housing        = { enabled = false, alpha = 0, priority = true },
            instance       = { enabled = true,  alpha = 1, priority = false },
            targetFriendly = { enabled = true,  alpha = 1, priority = false, softTarget = false },
            targetHostile  = { enabled = true,  alpha = 1, priority = false, softTarget = false },
        }

        local DEFAULT_GROUP = Config.GetDefaultGroup(L["name_defaultGroup"])

        local function ResolveOldCondition(c, name)
            local result = CopyTable(OLD_CONDITION_DEFAULTS[name])
            if c[name] then
                for k, v in pairs(c[name]) do
                    result[k] = v
                end
            end
            return result
        end

        function MergeGroups(defaultGroup, userGroup)
            local result = CopyTable(defaultGroup)

            for key, value in pairs(userGroup) do
                if type(value) == "table" and type(result[key]) == "table" then
                    result[key] = MergeGroups(result[key], value)
                else
                    result[key] = value
                end
            end

            return result
        end

        local function MigrateGroup(group)
            local c = group.conditions
            if not c then
                -- is using defaults
                return
            end

            local housing  = ResolveOldCondition(c, "housing")
            local instance = ResolveOldCondition(c, "instance")
            local tFriendly = ResolveOldCondition(c, "targetFriendly")
            local tHostile  = ResolveOldCondition(c, "targetHostile")

            -- instance and housing
            c.instanceNeighborhood = CopyTable(housing)
            c.instanceHousing      = CopyTable(housing)

            if housing.alpha ~= instance.alpha or housing.priority ~= instance.priority then
                c.instanceNeighborhood.customize = true
                c.instanceHousing.customize      = true
            else
                c.instanceNeighborhood.customize = false
                c.instanceHousing.customize      = false
            end

            if housing.enabled and not instance.enabled then
                c.instance = c.instance or {}
                c.instance.enabled = true
                for _, name in ipairs({ "instanceDungeon", "instanceRaid", "instanceBattleground", "instanceArena", "instanceScenario" }) do
                    c[name] = c[name] or {}
                    c[name].enabled = false
                end
            end

            c.housing = nil

            -- target and focus
            local targetEnabled = tFriendly.enabled or tHostile.enabled

            local targetSettingsMatch = tFriendly.alpha == tHostile.alpha
                            and tFriendly.priority  == tHostile.priority
                            and tFriendly.softTarget == tHostile.softTarget

            if targetSettingsMatch then
                c.target = CopyTable(tFriendly)
                c.focus  = CopyTable(tFriendly)
                c.targetFriendly = c.targetFriendly or {}
                c.targetHostile  = c.targetHostile  or {}
                c.targetFriendly.customize = false
                c.targetHostile.customize  = false
                c.focusFriendly = CopyTable(tFriendly)
                c.focusHostile  = CopyTable(tHostile)
                c.focusFriendly.customize = false
                c.focusHostile.customize  = false
            else
                c.target = CopyTable(Config.GetDefaultConditionByName("target").db)
                c.focus  = CopyTable(Config.GetDefaultConditionByName("focus").db)
                c.targetFriendly = c.targetFriendly or {}
                c.targetHostile  = c.targetHostile  or {}
                c.targetFriendly.customize = true
                c.targetHostile.customize  = true
                c.focusFriendly = CopyTable(tFriendly)
                c.focusHostile  = CopyTable(tHostile)
                c.focusFriendly.customize = true
                c.focusHostile.customize  = true
            end

            c.target.enabled = targetEnabled
            c.focus.enabled  = targetEnabled
            c.focusFriendly.softTarget = nil
            c.focusHostile.softTarget  = nil
        end

        local function CheckGroupForMissingEntries(group)
            -- AceDB would not keep user's groups up to date with updates to conditions.
            -- doing a one-time check here to update everything and use migrationFunc feature in the future.

            -- looking for missing settings
            for k,v in pairs(DEFAULT_GROUP) do
                if not group[k] then
                    if type(v) == "table" then
                        group[k] = CopyTable(v)
                    else
                        group[k] = v
                    end
                end
            end

            -- looking for missing conditions
            for conditionName, conditionInfo in pairs(DEFAULT_GROUP.conditions) do
                if not group.conditions[conditionName] then
                    group.conditions[conditionName] = CopyTable(conditionInfo)
                else
                    for setting, value in pairs(conditionInfo) do
                        if group.conditions[conditionName][setting] == nil then
                            group.conditions[conditionName][setting] = value
                        end
                    end
                end
            end

            -- checking for settings that are no longer in use
            for k,v in pairs(group) do
                if DEFAULT_GROUP[k] == nil then
                    group[k] = nil
                end
            end
        end

        local newProfile = {
            groups= {},
            manualControl = {}
        }

        -- not doing ipairs because first entry will be nil if it's a default group, stoppig the loop
        for i, group in pairs(profile) do
            MigrateGroup(group)
            CheckGroupForMissingEntries(group)
        end

        -- going forward, defaultGroup is not included in defaultProfile anymore.
        -- therefore we need to hard assign it's values here. 
        if profile[1] == nil then
            profile[1] = CopyTable(DEFAULT_GROUP)
        else
            local mergedTable = MergeGroups(DEFAULT_GROUP, profile[1])
            profile[1] = mergedTable
        end


        newProfile.groups = profile

        return newProfile
    end,

    -- handling override hotkeys differently. middle mouse button is no longer supported.
    [2] = function(profile, profileName)
        if not profile.manualControl then
            return profile
        end

        local printMessage = false
        for _, info in ipairs(profile.manualControl) do
            if string.match(info.keybind, "MiddleButton") then
                info.keybind = ""
                info.keybindDisplay = ""
                printMessage = true
            end
        end

        if printMessage then
            local title = Main.GetErrorTitleString()
            local message = L["warning_schema2"]
            print(title..message..Main.ColorString(profileName, "red"))
        end

        return profile
    end,

    [3] = function(profile, profileName)
        Migration.AddCondition(profile, "isInteracting")
        Migration.RenameCondition(profile, "interactable", "canInteract")
    end,

}

function Migration.AddCondition(profile, conditionName)
    local newConditionDB

    for _, conditionInfo in pairs(Private.ConditionsTab.CONDITION_DEFINITIONS) do
        if conditionInfo.name == conditionName then
            newConditionDB = conditionInfo.db
            break
        end
    end

    -- necessary check!
    -- when migrating from a really old build, we might be looking for a condition that got removed since
    if not newConditionDB then
        return
    end

    if profile.groups then
        for i, groupData in pairs(profile.groups) do
            groupData.conditions[conditionName] = CopyTable(newConditionDB)
        end
    end

end

function Migration.RemoveCondition(profile, conditionName)
    if profile.groups then
        for i, groupData in pairs(profile.groups) do
            groupData.conditions[conditionName] = nil
        end
    end
end

function Migration.RenameCondition(profile, oldName, newName)
    if profile.groups then
        for i, groupData in pairs(profile.groups) do
            if not groupData.conditions[newName] then
                groupData.conditions[newName] = groupData.conditions[oldName]
                groupData.conditions[oldName] = nil
            end
        end
    end
end

function Migration.AddFrame(profile, frameName)
    local frameState

    for _, frameInfo in pairs(Private.FramesTab.DEFAULT_FRAMES) do
        if frameInfo.frame == frameName then
            frameState = frameInfo.enabled
            break
        end
    end

    -- necessary check!
    -- when migrating from a really old build, we might be looking for a frame that got removed since
    if frameState == nil then
        return
    end

    if profile.groups then
        for i, groupData in pairs(profile.groups) do
            groupData.frames[frameName] = frameState
        end
    end
end

function Migration.RemoveFrame(profile, frameName)
    if profile.groups then
        for i, groupData in pairs(profile.groups) do
            groupData.frames[frameName] = nil
        end
    end
end

function Migration.UpdateDB()
    local lastSchemaVersion = Private.db.global.db_schema or 0

    for i = lastSchemaVersion + 1, DB_SCHEMA_VERSION do
        local migrationFunc = MigrationDB[i]
        if migrationFunc then
            -- migrating every profile
            for profileName, profile in pairs(Private.db.profiles) do
                local newProfile = migrationFunc(profile, profileName)
                if newProfile then
                    Private.db.profiles[profileName] = newProfile
                end
            end
        end
    end

    Private.db.global.db_schema = DB_SCHEMA_VERSION
end