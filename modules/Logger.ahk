; ===== STRUCTURED RUN LOGGING =====
InitializeLogger() {
    global LOG_DIR, RUN_LOG_FILE, RELEASE_BUILD

    if (RELEASE_BUILD) {
        RUN_LOG_FILE := ""
        return
    }

    EnsureDirectory(LOG_DIR)
    timestamp := FormatTime(, "yyyyMMdd-HHmmss")
    RUN_LOG_FILE := LOG_DIR "\run-" . timestamp . ".log"

    LogEvent("INFO", "ScriptStarted", {
        script: A_ScriptName,
        version: A_AhkVersion,
        screenW: A_ScreenWidth,
        screenH: A_ScreenHeight
    })
}

LogEvent(level, eventName, data := "") {
    global RUN_LOG_FILE, RELEASE_BUILD

    if (RELEASE_BUILD) {
        return
    }

    if (RUN_LOG_FILE = "") {
        return
    }

    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    line := ts . " | " . level . " | " . eventName

    payload := SerializeLogData(data)
    if (payload != "") {
        line .= " | " . payload
    }

    try {
        FileAppend(line . "`n", RUN_LOG_FILE, "UTF-8")
    }
}

PrintStatus(message) {
    global PRINT_STATUS_TO_CONSOLE

    if (!PRINT_STATUS_TO_CONSOLE) {
        return
    }

    line := FormatTime(, "yyyy-MM-dd HH:mm:ss") . " | STATUS | " . message
    try {
        FileAppend(line . "`n", "*", "UTF-8")
    } catch {
        try OutputDebug(line)
    }
}

SerializeLogData(data) {
    if (IsObject(data)) {
        if (Type(data) = "Array") {
            values := []
            for value in data {
                values.Push(SerializeScalar(value))
            }
            return "[" . JoinWith(values, ", ") . "]"
        }

        parts := []
        for pair in EnumerateObject(data) {
            parts.Push(pair[1] . "=" . SerializeScalar(pair[2]))
        }
        return JoinWith(parts, " ")
    }

    return SerializeScalar(data)
}

SerializeScalar(value) {
    if (IsObject(value)) {
        return SerializeLogData(value)
    }

    text := value . ""
    text := StrReplace(text, "`r", "\r")
    text := StrReplace(text, "`n", "\n")
    return text
}

EnumerateObject(obj) {
    pairs := []

    if (Type(obj) = "Map") {
        for key, value in obj {
            pairs.Push([key, value])
        }
        return pairs
    }

    ; Plain objects expose OwnProps, maps expose key-value iteration directly.
    if (obj.HasMethod("OwnProps")) {
        for key, value in obj.OwnProps() {
            pairs.Push([key, value])
        }
        return pairs
    }

    for key, value in obj {
        pairs.Push([key, value])
    }
    return pairs
}

JoinWith(arr, separator) {
    out := ""
    for index, item in arr {
        if (index > 1) {
            out .= separator
        }
        out .= item
    }
    return out
}
