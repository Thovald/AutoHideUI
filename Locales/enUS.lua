local L = LibStub("AceLocale-3.0"):NewLocale("AutoHideUI", "enUS", true)

-- misc
L["error_optionsOpen"] = "Options Window needs to be open to change options!"

-- Main menu
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
L["descr_frames"] = "The same Frame can't be assigned to multiple Groups."
L["group_defaultFrames"] = "Common Frames"
L["group_customFrames"] = "Custom Frames"
L["descr_customFrames"] =   "Use the Frame Finder or manually add the name of any Frame here.".."|n"..
                            "Separate multiple entries with a comma."
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
L["CDM Bars"] = true
L["CDM Buffs"] = true
L["CDM Essential"] = true
L["CDM Utility"] = true
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
L["priority"] = "Priority Condition"

L["label_combat"] = "In Combat"
L["label_instance"] = "In Instance"
L["label_mouseover"] = "On Mouseover"
L["label_target"] = "Has Target"
L["label_targetFriendly"] = "Friendly"
L["label_targetHostile"] = "Hostile"
L["label_focus"] = "Has Focus"
L["label_focusFriendly"] = "Friendly"
L["label_focusHostile"] = "Hostile"
L["label_casting"] = "Casting"
L["label_resting"] = "Resting"
L["label_health"] = "Missing Health"
L["label_mounted"] = "Mounted"
L["label_inVehicle"] = "In Vehicle"
L["descr_health"] = "Due to AddOn restrictions, this relies entirely on workarounds."..
                    "|n|n"..
                    "When below 35% Health:".."|n"..
                    "Requires the game option 'Do Not Flash Screen at Low Health' to be disabled."..
                    "|n|n"..
                    "When hurt:".."|n"..
                    "Works by monitoring health events.".."|n"..
                    "Assumes you're at full health if no health event fired for 3sec."

L["dropdown_druidForms"] = "Include Druid Forms"
L["dropdownOption_druid1"] = "Land/Air/Water"
L["dropdownOption_druid2"] = "Land/Air"
L["dropdownOption_druid3"] = "None"

L["chatCommands"] = "Chat Commands:"

L["dropdown_health"] = "Show when ..."
L["dropdownOption_health1"] = "below 35% HP"
L["dropdownOption_health2"] = "player is hurt"
L["dropdownOption_health3"] = "party is hurt"
L["dropdownOption_health4"] = "player/party is hurt"

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
L["button_reset"] = "Reset to Defaults"

L["frameFinder"] = "Frame Finder"
L["descr_frameFinder"] = "Launches a Tool to help you find and add Frames that aren't listed above."
L["ffButton_clear"] = "Clear Selection"
L["ffDescr_howTo"] =    "Mouseover a Frame".."|n"..
                        "Mousewheel to cycle through Frames".."|n"..
                        "Cycle until correct Frame is fading".."|n"..
                        "Click to select/deselect".."|n|n"..
                        "or".."|n|n"..
                        "Browse the list on the left".."|n"..
                        "Click to select/deselect".."|n"
L["ffButton_confirm"] = "Accept Selection"
L["ffButton_cancel"] = "Cancel"
L["ffTitle_available"] = "Available Custom Frames"
L["title_howTo"] = "How to Use"
L["descr_ActionBar1"] = "This bar includes all extra-bars an AddOn may include.".."|n|n"..
                        "If unwanted, disable this bar and manually add the names of the bars you want in the Custom Frames section below.".."|n|n"..
                        "Useful if you want some extra-bars to not fade or to assign them to a different group."

L["dropdown_mouseover"] = "Triggered by"
L["dropdownOption_mouseover1"] = "this Group only"
L["dropdownOption_mouseover2"] = "any Group"
L["descr_mouseover"] = "Should this only respond to mousing over Frames of this Group?".."|n|n"..
                        "Or should this respond to mouseover events from any Group?"

L["checkbox_priority"] = "Priority Condition"
L["description_priority"] = "The Alpha of active Priority Conditions always wins out against the Alpha of normal Conditions".."|n|n"..
                            "For example, if the 'Instance' Condition is a priority and its Alpha is 0, your Frames will fade out when you're in a Dungeon.".."|n|n"..
                            "Even when 'Combat' or 'Mouseover' want to set it to 1, it will remain at 0.".."|n|n"..
                            "Only another Priority Condition can now fight this 'Instance' Condition on the Alpha.".."|n|n"..
                            "You could use this to always hide your CooldownManager when in a vehicle, while having it fade normally when not in a vehicle."
L["label_housing"] = "Housing/Neighborhood"

L["Personal Resource"] = true

L["mouseoverAreas"] = "Mouseover Areas"
L["descr_mouseoverAreas"] = "Create custom areas that can trigger a mouseover event."
L["button_newArea"] = "New Area"
L["button_close"] = "Close"
L["ffDescr_howToMouseoverAreas"] = "Create a new area.".."|n|n"..
                                "Left click to move/resize.".."|n|n"..
                                "Right click to delete."

L["label_instanceDungeon"] = "Dungeon"
L["label_instanceRaid"] = "Raid"
L["label_instanceBattleground"] = "Battleground"
L["label_instanceArena"] = "Arena"
L["label_instanceScenario"] = "Delve/Scenario"
L["label_instanceNeighborhood"] = "Neighborhood"
L["label_instanceHousing"] = "House Interior"

L["customize"] = "Customize"
L["description_override"] = "When enabled, this Condition will ignore the settings of the parent and instead use its own settings."
L["expand"] = "Expand"
L["collapse"] = "Collapse"
L["buttonChangelog"] = "View Changelog"
L["tab_manualControl"] = "Manual Control"
L["descr_manualControl"] = "Define a Keybind or Macro to manually set the Alpha of your Groups.".."|n|n"..
                            "While an override is engaged, affected Groups will be set to that Alpha and ignore Conditions.".."|n|n"..
                            "When disengaged, the Groups will go back to using Conditions to determine their Alpha."
L["button_newOverride"] = "New Override"
L["name_newGroup"] = "New Group"
L["popup_createOverride"] = "Name of new Override:"
L["name_newOverride"] = "New Override"
L["popup_renameOverride"] = "Rename Override"
L["popup_deleteOverride"] = "Delete Override"
L["button_setHotkey"] = "No Keybind"
L["button_setHotkeyRecording"] = "Recording ..."
L["description_setHotkey"] = "Click to set a new Keybind.".."|n"..
                             "Esc or Right-Click to clear."
L["input_macro"] = "Macro (optional)"
L["description_macro"] = "In addition or instead of a keybind, you can use a macro to toggle this override.".."|n|n"..
                         "Make the following macro and replace 'MyMacro' with your custom word:".."|n|n"..
                         "/autohide override MyMacro"
L["dropdown_affectedGroups"] = "Affected Groups"
L["dropdownOption_affectedGroups1"] = "All"
L["dropdownOption_affectedGroups2"] = "Customize"
L["print_overrideResult"] = "AutoHideUI Override: "
L["checkbox_printOverride"] = "Print Results"
L["description_printOverride"] = "Prints out a message in your chat showing which groups are now controlled by an override."
L["print_duplicateKeybind"] = "Duplicate keybind '%s' removed from Override '%s' !"
L["print_duplicateMacro"] = "Duplicate macro '%s' removed from Override '%s' !"

L["mouseMiddle"] = "MiddleMouse"
L["mouseBtn4"] = "Mouse4"
L["mouseBtn5"] = "Mouse5"
L["num+"] = "NumPlus"
L["num-"] = "NumMinus"
L["pageUp"] = "PageUp"
L["pageDown"] = "PageDown"
L["ctrl"] = "Ctrl"
L["alt"] = "Alt"
L["shift"] = "Shift"

L["print_resetSuccess"] = "Current Profile has been reset!"
L["header_viewingGroup"] = "Viewing Group: "

L["print_switchMissing"] = "Profile does not exist: "
L["print_switchSame"] = "Already set to Profile: "
L["print_switchSuccess"] = "Switched to Profile: "
L["print_toggleError1"] = "Need to provide two profile names!"
L["print_toggleError2"] = "Both profiles are the same!"
L["print_toggleError3"] = "These profiles don't exist: "
L["warning_schema2"] = "Middle Mouse Button is no longer supported!|nA Hotkey in the following Profile has been reset: "

L["Show active Frames:"] = true
L["Common"] = true
L["Custom"] = true
L["Mouseover"] = true
