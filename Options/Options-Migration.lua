local _, Private = ...
local L = LibStub("AceLocale-3.0"):GetLocale("AutoHideUI")

local Main = Private.Main
local Migration = Private.Migration
local Config = Private.Config

Main.DB_SCHEMA_VERSION = 3

local MigrationDB = {
    -- when parent/child conditions, manualControl and mouseover areas were introduced
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

        local function MergeGroups(defaultGroup, userGroup)
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

        local newProfile = Config.GetDefaultProfile().profile

        -- Keep profile-level settings out of the group list.
        for i, group in pairs(profile) do
            if type(i) == "number" and type(group) == "table" and group.name then
                MigrateGroup(group)
                CheckGroupForMissingEntries(group)
                newProfile.groups[i] = group
            end
        end

        -- going forward, defaultGroup is not included in defaultProfile anymore.
        -- therefore we need to hard assign it's values here. 
        if newProfile.groups[1] == nil then
            newProfile.groups[1] = CopyTable(DEFAULT_GROUP)
        else
            local mergedTable = MergeGroups(DEFAULT_GROUP, newProfile.groups[1])
            newProfile.groups[1] = mergedTable
        end

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

function Migration.LastVersionIsOlderThan(version)
    local lastVersion = Private.db.global.last_version or "0.0.0"
    local lastMajor, lastMinor, lastPatch = strsplit(".", lastVersion)
    local major, minor, patch = strsplit(".", version)

    if tonumber(lastMajor) < tonumber(major) then
        return true
    elseif tonumber(lastMajor) == tonumber(major) and tonumber(lastMinor) < tonumber(minor) then
        return true
    elseif tonumber(lastMajor) == tonumber(major) and tonumber(lastMinor) == tonumber(minor) and tonumber(lastPatch) < tonumber(patch) then
        return true
    end

    return false
end

function Migration.IsModernDB()
    for profileName, profile in pairs(Private.db.profiles) do
        for i, group in pairs(profile) do
            if type(i) == "number" and type(group) == "table" then
                return false
            else
                return true
            end
        end
    end
    return false
end

function Migration.HandleModernDB()
    -- since its introduction, we never wrote the current schema version to the db of fresh installs ... oops!
    -- on fresh installs that triggered an attempt to migrate a modern db, resulting in an error and a bricked profile.
    -- it's fixed in 1.2.20, but bricked profiles from before that will need to be reset.
    if Migration.LastVersionIsOlderThan("1.2.19") then
        Migration.ResetCorruptedModernDB()
    end

    Private.db.global.db_schema = Main.DB_SCHEMA_VERSION
end

function Migration.ResetCorruptedModernDB()
    local defaultProfile = Config.GetDefaultProfile().profile
    local defaultGroup = Config.GetDefaultGroup(L["name_defaultGroup"])
    tinsert(defaultProfile.groups, defaultGroup)

    for profileName, profile in pairs(Private.db.profiles) do
        for origKey, origVal in pairs(profile) do

            if defaultProfile[origKey] == nil then
                profile[origKey] = nil
            end

            for newKey, newVal in pairs(defaultProfile) do
                if type(newVal) == "table" then
                    profile[newKey] = CopyTable(newVal)
                else
                    profile[newKey] = newVal
                end
            end

        end
    end

    Main.ReInitAddon()
end

function Migration.UpdateDB()
    local lastSchemaVersion = Private.db.global.db_schema or 0

    -- fresh installs will have a schema version of 0
    if lastSchemaVersion == 0 and Migration.IsModernDB() then
        Migration.HandleModernDB()
        return
    end

    for i = lastSchemaVersion + 1, Main.DB_SCHEMA_VERSION do
        local migrationFunc = MigrationDB[i]
        if migrationFunc then
            -- migrating every profile
            for profileName, profile in pairs(Private.db.profiles) do
                local newProfile = migrationFunc(profile, profileName)
                if newProfile and newProfile ~= profile then
                    for key in pairs(profile) do
                        profile[key] = nil
                    end
                    for key, value in pairs(newProfile) do
                        profile[key] = value
                    end
                end
            end
        end
    end

    if lastSchemaVersion ~= Main.DB_SCHEMA_VERSION then
        Main.ReInitAddon()
    end

    Private.db.global.db_schema = Main.DB_SCHEMA_VERSION
end