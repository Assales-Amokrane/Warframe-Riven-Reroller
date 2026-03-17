; ===== RELEASE HOTKEYS =====

F8:: {
    ShowProfileOverviewDialog("Riven Reroller Ready")
}

F9:: {
    StartRerollLoop()
}

F10:: {
    global IS_RUNNING
    if (IS_RUNNING) {
        StopRerollLoop("User stopped")
    }
}

Esc:: {
    global IS_RUNNING
    if (IS_RUNNING) {
        StopRerollLoop("Exited with Esc")
    }
    ExitApp
}
