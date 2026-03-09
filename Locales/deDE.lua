local L = LibStub("AceLocale-3.0"):NewLocale("AutoHideUI", "deDE")
if not L then return end

-- misc
L["error_optionsOpen"] = "Das Options Menü muss geöffnet sein um Optionen zu ändern!"

-- main menu
L["descr_groups"] = "Erstelle Gruppierungen um andere Einstellungen für andere Frames zu verwenden"
L["tab_setup"] = "Konfiguration"
L["dropdown_groupSelect"] = "Gruppierungen"
L["name_defaultGroup"] = "Standard Gruppierung"
L["button_newGroup"] = "Neue Gruppierung"
L["button_renameGroup"] = "Umbenennen"
L["button_deleteGroup"] = "Löschen"
L["button_create"] = "Erstellen"
L["button_rename"] = "Umbenennen"
L["button_delete"] = "Löschen"
L["button_cancel"] = "Abbrechen"
L["popup_deleteGroup"] = "Ausgewählte Gruppierung löschen?"
L["popup_renameGroup"] = "Gruppierung umbenennen:"
L["popup_createGroup"] = "Name für neue Gruppierung:"

-- tab: frame selection
L["tab_frameSelect"] = "Frame Auswahl"
L["descr_frames"] = "Ein Frame kann nicht mehreren Gruppierung zugewiesen werden.|nElvUI, Details, UUF und Dominos werden automatisch erkannt. Bartender ist inkompatibel."
L["group_defaultFrames"] = "Gewöhnliche Frames"
L["group_customFrames"] = "Benutzerdefinierte Frames"
L["descr_customFrames"] = "Gebe hier die Namen beliebiger Frames ein. Trenne sie mit einem Komma."
L["descr_Minimap"] = "Die Minikarte ist ein Sonderfall!|n|nAm besten sollte sie im Kampf einen Alpha Wert von 1 haben und wenn sie ausgeblendet wird, sollte sie auf einen Alpha Wert von 0 gehen."

L["Player Frame"] = "Spieler"
L["Target Frame"] = "Ziel"
L["Focus Frame"] = "Fokus"
L["Pet Frame"] = "Begleiter"
L["Party Frame"] = "Gruppe"
L["Objectives Frame"] = "Quest Liste"
L["ActionBar 1"] = "Aktionsleiste 1"
L["ActionBar 2"] = "Aktionsleiste 2"
L["ActionBar 3"] = "Aktionsleiste 3"
L["ActionBar 4"] = "Aktionsleiste 4"
L["ActionBar 5"] = "Aktionsleiste 5"
L["ActionBar 6"] = "Aktionsleiste 6"
L["ActionBar 7"] = "Aktionsleiste 7"
L["ActionBar 8"] = "Aktionsleiste 8"
L["Stance Bar"] = "Haltungsanzeige"
L["Pet Bar"] = "Haustierbalken"
L["Micro Menu"] = "Mikro Menü"
L["Bags Bar"] = "Taschen Menü"
L["CDManager Bars"] = "CDManager Balken"
L["CDManager Buffs"] = true
L["CDManager Essential"] = "CDManager Essenziell"
L["CDManager Utility"] = "CDManager Strategisch"
L["Buff Frame"] = "Verstärkungszauber"
L["Debuff Frame"] = "Schwächungszauber"
L["Player Castbar"] = "Zauberbalken"
L["Damage Meter"] = "Schadensanzeige"
L["Minimap"] = "Minikarte"
L["Experience Bar"] = "Erfahrungsbalken"

-- tab: fade behavior
L["tab_fadeSetup"] = "Fade Einstellungen"
L["group_fadeAnimation"] = "Fade Animation"
L["slider_fadeOutDelay"] = "Warte vorm Ausblenden"
L["slider_fadeInDelay"] = "Warte vorm Einblenden"
L["slider_fadeDuration"] = "Dauer der Fade Animation"

L["group_alpha"] = "Alpha"
L["slider_idleAlpha"] = "Alpha wenn keine Konditionen aktiv sind"
L["checkbox_forceAlpha"] = "Erzwinge Alpha bei AddOn-Frames"
L["desc_forceAlpha"] = "Verhindert, dass andere AddOns mit Auto Hide UI über die Alpha ihrer Frames streiten.|n|nBetrifft nur Frames, die Auto Hide UI tatsächlich gerade benutzt."

L["descr_alphaPref"] = "Die unteren Einstellungen bestimmen für welche Alpha sich entschieden wird, wenn mehrere (Prio-)Bedingungen gleichzeitig aktiv sind."
L["dropdown_alphaPref"] = "Alpha Vorzug bei normalen Bedingungen"
L["tooltip_alphaPref"] = "Welcher Bedingungs-Alpha-Wert gewählt werden soll wenn mehrere Bedingungen aktiv sind."
L["dropdown_prioAlphaPref"] = "Alpha Vorzug bei Prio-Bedingungen"
L["tooltip_prioAlphaPref"] = "Welcher Priorität-Bedingungs-Alpha-Wert gewählt werden soll wenn mehrere Priorität-Bedingungen aktiv sind."
L["Highest"] = "Höchste"
L["Lowest"] = "Niedrigste"

-- tab: fade conditions
L["tab_fadeConditions"] = "Fade Bedingungen"
L["group_conditions"] = "Bedingungen"
L["descr_conditions"] = "Bestimme welche Bedingungen die Frames einblenden und ihren Alpha Wert.|Sind keine Bedingungen aktiv, wird die Alpha in 'Fade Einstellungen' verwendet."
L["descr_prioConditions"] = "Bedingungen können zu Prioritäts-Bedingungen erhoben werden.|nWährend Prio-Bedingungen aktiv sind, nimmt deren Alpha immer Vorrang vor normalen Bedingungen."
L["enable"] = "Ein"
L["alpha"] = "Alpha"
L["priority"] = "Prio"

--L["header_conditions"] = "Conditions"
L["label_combat"] = "Im Kampf"
L["label_instance"] = "In einer Instanz"
L["label_mouseover"] = "Bei Mouseover"
L["label_targetFriendly"] = "Bei freundl. Ziel"
L["label_targetHostile"] = "Bei feindl. Ziel"
L["label_casting"] = "Beim Zaubern"
L["label_resting"] = "Beim Ausruhen"
L["label_health"] = "Gesundheit"
L["label_mounted"] = "Beim Reiten"
L["label_inVehicle"] = "In einem Fahrzeug"
L["descr_health"] = "Aufgrund von AddOn-Beschränkungen beruht dies auf provisorischen Lösungen."..
                    "|n|n"..
                    "Wenn unter 35% Gesundheit:".."|n"..
                    "Benötigt, dass die folgende Blizzard-Option ausgeschaltet ist:|n"..
                    "'Bildschirm bei niedriger Gesundheit nicht aufleuchten lassen'"..
                    "|n|n"..
                    "Bei fehlender Gesundheit:".."|n"..
                    "Funktioniert durch die Überwachung von Gesundheitsereignissen. Kein Ereignis bedeutet idR volle Gesundheit.".."|n"..
                    "Verfügt über Kontrollen um die meisten falsch-positiven Ergebnisse auszusortieren."

L["dropdown_druidForms"] = "Einschl. Druidenformen"
L["dropdownOption_druid1"] = "Land/Luft/Wasser"
L["dropdownOption_druid2"] = "Land/Luft"
L["dropdownOption_druid3"] = "Keine"

L["chatCommands"] = "Chat Befehle:"

L["dropdown_health"] = "Zeige ..."
L["dropdownOption_health1"] = "bei unter 35% Gesundheit"
L["dropdownOption_health2"] = "bei fehlender Gesundheit"
L["label_flying"] = "Beim Fliegen"
L["dropdown_flightStyle"] = "Flug Stil"
L["dropdownOption_flight1"] = "Nur Himmelsreiten"
L["dropdownOption_flight2"] = "Nur Statisch"
L["dropdownOption_flight3"] = "Beides"