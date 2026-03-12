local L = LibStub("AceLocale-3.0"):NewLocale("AutoHideUI", "enUS", true)

-- misc
L["error_optionsOpen"] = "Options Window needs to be open to change options!"

-- main menu
L["descr_groups"] = "Create Groups to assign different settings to different Frames"
L["tab_setup"] = "Setup"
L["dropdown_groupSelect"] = "Group Selection"
L["name_defaultGroup"] = "Default Group"
L["button_newGroup"] = "New Group"
L["button_renameGroup"] = "Rename"
L["button_deleteGroup"] = "Delete"
L["button_create"] = "Create"
L["button_rename"] = "Rename"
L["button_delete"] = "Delete"
L["button_cancel"] = "Cancel"
L["popup_deleteGroup"] = "Delete selected Group?"
L["popup_renameGroup"] = "Rename Group:"
L["popup_createGroup"] = "Name of new Group:"

-- tab: frame selection
L["tab_frameSelect"] = "Frame Selection"
L["descr_frames"] = "The same Frame can't be assigned to multiple Groups.|nElvUI, Details, UUF and Dominos will automatically be detected. Bartender won't work."
L["group_defaultFrames"] = "Common Frames"
L["group_customFrames"] = "Custom Frames"
L["descr_customFrames"] = "Add the names of any other Frame here. Separate them with commas."
L["descr_Minimap"] = "The minimap is a special case!|n|nFor best results, set it to be at full Alpha when in combat and at 0 Alpha when faded out."

L["Player Frame"] = true
L["Target Frame"] = true
L["Focus Frame"] = true
L["Pet Frame"] = true
L["Party Frame"] = true
L["Objectives Frame"] = true
L["ActionBar 1"] = true
L["ActionBar 2"] = true
L["ActionBar 3"] = true
L["ActionBar 4"] = true
L["ActionBar 5"] = true
L["ActionBar 6"] = true
L["ActionBar 7"] = true
L["ActionBar 8"] = true
L["Stance Bar"] = true
L["Pet Bar"] = true
L["Micro Menu"] = true
L["Bags Bar"] = true
L["CDManager Bars"] = true
L["CDManager Buffs"] = true
L["CDManager Essential"] = true
L["CDManager Utility"] = true
L["Buff Frame"] = true
L["Debuff Frame"] = true
L["Player Castbar"] = true
L["Damage Meter"] = true
L["Minimap"] = true
L["Experience Bar"] = true


-- tab: fade behavior
L["tab_fadeSetup"] = "Fade Settings"
L["group_fadeAnimation"] = "Fade Animation"
L["slider_fadeOutDelay"] = "Delay before fading out"
L["slider_fadeInDelay"] = "Delay before fading in"
L["slider_fadeDuration"] = "Duration of Fade-Animation"

L["group_alpha"] = "Alpha"
L["slider_idleAlpha"] = "Alpha when no Conditions are active"
L["checkbox_forceAlpha"] = "Force Alpha on AddOn-Frames"
L["desc_forceAlpha"] = "Enable this to stop other AddOns fighting with Auto Hide UI over the Alpha of their Frames.|n|nOnly affects Frames that are actually in use by Auto Hide UI."

L["descr_alphaPref"] = "The settings below determine which Alpha to choose when multiple (Prio-)Conditions are active at the same time."
L["dropdown_alphaPref"] = "Condition-Alpha Preference"
L["tooltip_alphaPref"] = "Which Condition's Alpha to choose when multiple Conditions are active."
L["dropdown_prioAlphaPref"] = "Prio-Condition-Alpha Preference"
L["tooltip_prioAlphaPref"] = "Which Priority-Condition's Alpha to choose when multiple Priority-Conditions are active."
L["Highest"] = true
L["Lowest"] = true

-- tab: fade conditions
L["tab_fadeConditions"] = "Fade Conditions"
L["group_conditions"] = "Conditions"
L["descr_conditions"] = "Enable which Conditions should fade the Frames and what Alpha they should fade to.|nWhile no Condition is active, the Alpha in the 'Fade Settings' tab is used."
L["descr_prioConditions"] = "Conditions can be promoted to Priority-Conditions.|nIf a Priority-Condition is active, their Alpha only competes with other Priority-Conditions.|nThe Alpha of any normal Conditions isn't even considered in that case."
L["enable"] = "Enable"
L["alpha"] = "Alpha"
L["priority"] = "Prio"

L["label_combat"] = "In Combat"
L["label_instance"] = "In Instance"
L["label_mouseover"] = "On Mouseover"
L["label_targetFriendly"] = "Friendly Target/Focus"
L["label_targetHostile"] = "Hostile Target/Focus"
L["label_casting"] = "Casting"
L["label_resting"] = "Resting"
L["label_health"] = "Health"
L["label_mounted"] = "Mounted"
L["label_inVehicle"] = "In Vehicle"
L["descr_health"] = "Due to AddOn restrictions, this relies entirely on workarounds."..
                    "|n|n"..
                    "When below 35% Health:".."|n"..
                    "Requires the game option 'Do Not Flash Screen at Low Health' to be disabled."..
                    "|n|n"..
                    "When missing Health:".."|n"..
                    "Works by monitoring health events.".."|n"..
                    "Assumes you're at full health if no health event fired for 3sec."

L["dropdown_druidForms"] = "Include Druid Forms"
L["dropdownOption_druid1"] = "Land/Air/Water"
L["dropdownOption_druid2"] = "Land/Air"
L["dropdownOption_druid3"] = "None"

L["chatCommands"] = "Chat Commands:"

L["dropdown_health"] = "Show when ..."
L["dropdownOption_health1"] = "below 35% HP"
L["dropdownOption_health2"] = "missing health"
L["label_flying"] = "Flying"
L["dropdown_flightStyle"] = "Flight Style"
L["dropdownOption_flight1"] = "Only Skyriding"
L["dropdownOption_flight2"] = "Only Steady Flight"
L["dropdownOption_flight3"] = "Both"

L["checkbox_softTarget"] = "Incl. Soft Target"
L["descr_softTarget"] = "For players that have the game's 'Action Targeting' option enabled."
L["label_interactable"] = "Can Interact"
L["descr_interactable"] = "When something interactable is in reach of the player character."
L["checkbox_excludeNPCs"] = "Exclude NPCs"
L["descr_excludeNPCs"] = "Will ignore interactable objects that can be targeted, like NPCs."
L["button_disableAll"] = "Disable All"
L["button_reset"] = "Reset Group to Default"

