; ---------------------------------------------------------------------
; ===== MAIN LOOP =====
; ---------------------------------------------------------------------

; ===== MAIN REROLL LOOP =====
StartRerollLoop() {
    global IS_RUNNING, CURRENT_CYCLE, REROLL_ENABLED, ACTIVE_PROFILE, STOP_AFTER_CONFIRM, STOP_REASON_AFTER_CONFIRM, MAX_CYCLES
    global LAST_DETECTED_STATE, LAST_STATE_STREAK, LAST_LOGGED_REROLL_STATE, UNKNOWN_REROLL_STATE_STREAK, LAST_REROLL_STATUS_LINE

    if (!REROLL_ENABLED) {
        MsgBox("Please load a profile first (F8).", "Error")
        return
    }

    if (!ACTIVE_PROFILE.HasOwnProp("profileId")) {
        MsgBox("No valid profile loaded. Press F8 and load a JSON export.", "Error")
        return
    }

    if (IS_RUNNING) {
        MsgBox("Reroll loop is already running!", "Error")
        return
    }

    if (!EnsureWarframeWindow()) {
        MsgBox("Warframe must be open and focusable before starting the reroll loop.", "Error")
        return
    }

    CURRENT_CYCLE := 0
    STOP_AFTER_CONFIRM := false
    STOP_REASON_AFTER_CONFIRM := ""
    LAST_DETECTED_STATE := ""
    LAST_STATE_STREAK := 0
    LAST_LOGGED_REROLL_STATE := ""
    UNKNOWN_REROLL_STATE_STREAK := 0
    LAST_REROLL_STATUS_LINE := ""
    IS_RUNNING := true

    LogEvent("INFO", "RerollStarted", {
        profileId: ACTIVE_PROFILE.profileId,
        profileName: ACTIVE_PROFILE.profileName,
        weaponName: ACTIVE_PROFILE.weaponName,
        maxCycles: MAX_CYCLES
    })

    PrintStatus(
        "Reroll started | Profile: " . ACTIVE_PROFILE.profileName
        . " | Max cycles: " . MAX_CYCLES
        . " | Press F10 to stop"
    )
    Sleep 150

    SetTimer(RerollStateMachine, 100)
}

StopRerollLoop(reason := "Manually stopped") {
    global IS_RUNNING, CURRENT_CYCLE, STOP_AFTER_CONFIRM, STOP_REASON_AFTER_CONFIRM
    global LAST_DETECTED_STATE, LAST_STATE_STREAK, LAST_LOGGED_REROLL_STATE, UNKNOWN_REROLL_STATE_STREAK, LAST_REROLL_STATUS_LINE

    IS_RUNNING := false
    SetTimer(RerollStateMachine, 0)

    STOP_AFTER_CONFIRM := false
    STOP_REASON_AFTER_CONFIRM := ""
    LAST_DETECTED_STATE := ""
    LAST_STATE_STREAK := 0
    LAST_LOGGED_REROLL_STATE := ""
    UNKNOWN_REROLL_STATE_STREAK := 0
    LAST_REROLL_STATUS_LINE := ""

    PrintStatus("Reroll stopped | Reason: " . reason . " | Total cycles: " . CURRENT_CYCLE)
    LogEvent("INFO", "RerollStopped", {reason: reason, totalCycles: CURRENT_CYCLE})
}

RerollStateMachine() {
    global IS_RUNNING, CURRENT_CYCLE, ACTION_DELAY, MAX_CYCLES, LOG_STATE_CHANGE_ONLY
    global LOG_UNKNOWN_STATES, UNKNOWN_LOG_STREAK, UNKNOWN_STATE_DELAY
    global UNKNOWN_STATE_DELAY_FAST, UNKNOWN_SLOW_DELAY_STREAK, UNKNOWN_STATUS_STREAK
    global LAST_LOGGED_REROLL_STATE, UNKNOWN_REROLL_STATE_STREAK, LAST_REROLL_STATUS_LINE

    if (!IS_RUNNING) {
        return
    }

    if (CURRENT_CYCLE >= MAX_CYCLES) {
        StopRerollLoop("Maximum cycles reached (" . MAX_CYCLES . ")")
        return
    }

    state := DetectState()
    statusLine := ""
    if (state = "Unknown") {
        UNKNOWN_REROLL_STATE_STREAK++
        if (UNKNOWN_REROLL_STATE_STREAK >= UNKNOWN_STATUS_STREAK) {
            statusLine := "State: Unknown | Cycle: " . CURRENT_CYCLE
        }
        if (LOG_UNKNOWN_STATES) {
            shouldLogUnknown := (!LOG_STATE_CHANGE_ONLY || state != LAST_LOGGED_REROLL_STATE) && (UNKNOWN_REROLL_STATE_STREAK >= UNKNOWN_LOG_STREAK)
            if (shouldLogUnknown) {
                LogEvent("INFO", "StateDetected", {state: state, cycle: CURRENT_CYCLE, streak: UNKNOWN_REROLL_STATE_STREAK})
                LAST_LOGGED_REROLL_STATE := state
            }
        }
    } else {
        UNKNOWN_REROLL_STATE_STREAK := 0
        statusLine := "State: " . state . " | Cycle: " . CURRENT_CYCLE
    }

    if (statusLine != "" && statusLine != LAST_REROLL_STATUS_LINE) {
        PrintStatus(statusLine)
        LAST_REROLL_STATUS_LINE := statusLine
    }

    if (state = "Error") {
        if (!LOG_STATE_CHANGE_ONLY || state != LAST_LOGGED_REROLL_STATE) {
            LogEvent("WARN", "StateDetected", {state: state, cycle: CURRENT_CYCLE})
            LAST_LOGGED_REROLL_STATE := state
        }
    } else if (state != "Unknown") {
        if (!LOG_STATE_CHANGE_ONLY || state != LAST_LOGGED_REROLL_STATE) {
            LogEvent("INFO", "StateDetected", {state: state, cycle: CURRENT_CYCLE})
            LAST_LOGGED_REROLL_STATE := state
        }
    }

    Switch state {
        Case "Cycle":
            HandleCycleState()
        Case "Confirm Cycle":
            HandleConfirmCycleState()
        Case "Selection":
            HandleSelectionState()
        Case "Confirm Selection":
            HandleConfirmSelectionState()
        Case "Unknown":
            unknownDelay := UNKNOWN_REROLL_STATE_STREAK >= UNKNOWN_SLOW_DELAY_STREAK ? UNKNOWN_STATE_DELAY : UNKNOWN_STATE_DELAY_FAST
            Sleep unknownDelay
        Case "Error":
            Sleep ACTION_DELAY
    }
}

HandleCycleState() {
    global OLD_RIVEN, ACTION_DELAY

    OLD_RIVEN := ReadRivenAttributes("old")
    if (OLD_RIVEN.HasOwnProp("error")) {
        PrintStatus("Error reading old riven attributes: " . OLD_RIVEN.error)
        LogEvent("WARN", "OldRivenReadFailed", {error: OLD_RIVEN.error})
        Sleep ACTION_DELAY
        return
    }

    LogEvent("INFO", "OldRivenRead", {count: OLD_RIVEN.count})

    if (!StartCycle()) {
        StopRerollLoop("Warframe window not focused while attempting to start cycle.")
        return
    }

    Sleep ACTION_DELAY
}

HandleConfirmCycleState() {
    global ACTION_DELAY

    if (!ConfirmCycleStart()) {
        StopRerollLoop("Warframe window not focused while confirming cycle.")
        return
    }

    Sleep ACTION_DELAY + 2000
}

HandleSelectionState() {
    global NEW_RIVEN, OLD_RIVEN, ACTION_DELAY, ACTIVE_RULES, STOP_AFTER_CONFIRM, STOP_REASON_AFTER_CONFIRM

    NEW_RIVEN := ReadRivenAttributes("new")
    if (NEW_RIVEN.HasOwnProp("error")) {
        PrintStatus("Error reading new riven attributes: " . NEW_RIVEN.error)
        LogEvent("WARN", "NewRivenReadFailed", {error: NEW_RIVEN.error})
        Sleep ACTION_DELAY
        return
    }

    winner := CompareRivens(OLD_RIVEN, NEW_RIVEN)

    oldCandidate := BuildCandidateFromParsedAttributes(OLD_RIVEN)
    newCandidate := BuildCandidateFromParsedAttributes(NEW_RIVEN)
    oldResult := EvaluateCandidate(ACTIVE_RULES, oldCandidate)
    newResult := EvaluateCandidate(ACTIVE_RULES, newCandidate)

    PrintStatus(
        "Old: " . oldResult.status . " D" . oldResult.desiredMatches
        . " | New: " . newResult.status . " D" . newResult.desiredMatches
        . " | Winner: " . winner
    )

    LogEvent("INFO", "RivenCompared", {
        winner: winner,
        oldStatus: oldResult.status,
        oldDesired: oldResult.desiredMatches,
        oldMandatory: oldResult.mandatoryMatches,
        newStatus: newResult.status,
        newDesired: newResult.desiredMatches,
        newMandatory: newResult.mandatoryMatches
    })

    if (winner = "old") {
        Sleep 500
        if (!PickOldRiven()) {
            StopRerollLoop("Warframe window not focused while picking old riven.")
            return
        }
        Sleep 500
    } else {
        if (IsPerfectRiven(NEW_RIVEN)) {
            STOP_AFTER_CONFIRM := true
            STOP_REASON_AFTER_CONFIRM := "Perfect riven found and confirmed."
            LogEvent("INFO", "PerfectRivenDetected", {action: "Will confirm new selection and stop"})
        }
    }

    if (!StartSelection()) {
        StopRerollLoop("Warframe window not focused while starting selection.")
        return
    }

    Sleep ACTION_DELAY
}

HandleConfirmSelectionState() {
    global ACTION_DELAY, CURRENT_CYCLE, STOP_AFTER_CONFIRM, STOP_REASON_AFTER_CONFIRM

    if (!ConfirmSelectionAction()) {
        StopRerollLoop("Warframe window not focused while confirming selection.")
        return
    }

    CURRENT_CYCLE++

    if (STOP_AFTER_CONFIRM) {
        reason := STOP_REASON_AFTER_CONFIRM != "" ? STOP_REASON_AFTER_CONFIRM : "Perfect riven confirmed."
        StopRerollLoop(reason)
        return
    }

    Sleep ACTION_DELAY
}
