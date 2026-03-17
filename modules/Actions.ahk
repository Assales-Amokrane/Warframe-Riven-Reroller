; ===== ACTIONS =====
StartCycle() {
    return SafeClickAction("startCycle")
}

ConfirmCycleStart() {
    return SafeClickAction("confirmCycleStart")
}

PickOldRiven() {
    return SafeClickAction("pickOldRiven")
}

StartSelection() {
    return SafeClickAction("startSelection")
}

ConfirmSelectionAction() {
    return SafeClickAction("confirmSelection")
}

SafeClickAction(actionName) {
    if (!EnsureWarframeWindow()) {
        LogEvent("WARN", "ActionSkippedWindowNotFocused", {action: actionName})
        return false
    }

    coords := GetActionCoord(actionName)
    Click coords.x, coords.y
    Sleep 100

    LogEvent("INFO", "ActionClick", {action: actionName, x: coords.x, y: coords.y})
    return true
}

EnsureWarframeWindow() {
    if (WinActive("ahk_exe Warframe.x64.exe")) {
        return true
    }

    ; Fallback for alternative executable naming or title-based matching.
    if (WinActive("Warframe")) {
        return true
    }

    if (ActivateWarframeWindow("ahk_exe Warframe.x64.exe")) {
        return true
    }
    if (ActivateWarframeWindow("Warframe")) {
        return true
    }

    return false
}

ActivateWarframeWindow(windowCriteria) {
    hwnd := WinExist(windowCriteria)
    if (!hwnd) {
        return false
    }

    windowRef := "ahk_id " . hwnd
    WinActivate(windowRef)
    WinWaitActive(windowRef, , 1)
    return WinActive(windowRef)
}
