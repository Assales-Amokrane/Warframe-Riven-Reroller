; ===== HOTKEYS =====

; Open the start/profile overview page
F8:: {
    ShowProfileOverviewDialog("Riven Reroller Ready")
}

; Run built-in parser/decision/state tests
F6:: {
    RunUnitTests()
}

; Start reroll loop
F9:: {
    StartRerollLoop()
}

; Stop reroll loop
F10:: {
    global IS_RUNNING
    if (IS_RUNNING) {
        StopRerollLoop("User stopped")
    }
}

; Show current riven evaluation (for debugging)
F11:: {
    global OLD_RIVEN, NEW_RIVEN, CURRENT_CYCLE, ACTIVE_PROFILE

    msg := "=== CURRENT STATUS ===`n`n"
    msg .= "Cycle: " . CURRENT_CYCLE . "`n"
    if (ACTIVE_PROFILE.HasOwnProp("profileName")) {
        msg .= "Profile: " . ACTIVE_PROFILE.profileName . "`n"
        msg .= "Weapon: " . ACTIVE_PROFILE.weaponName . "`n"
    }
    msg .= "`n"

    if (OLD_RIVEN.HasOwnProp("attributes")) {
        msg .= "OLD RIVEN:`n" . GetRivenSummary(OLD_RIVEN) . "`n`n"
    } else {
        msg .= "OLD RIVEN: n/a`n`n"
    }

    if (NEW_RIVEN.HasOwnProp("attributes")) {
        msg .= "NEW RIVEN:`n"
        msg .= GetRivenSummary(NEW_RIVEN)
    } else {
        msg .= "NEW RIVEN: n/a"
    }

    MsgBox(msg, "Current Status", "T10")
}

Esc:: {
    global IS_RUNNING
    if (IS_RUNNING) {
        StopRerollLoop("Exited with Esc")
    }
    ExitApp
}
