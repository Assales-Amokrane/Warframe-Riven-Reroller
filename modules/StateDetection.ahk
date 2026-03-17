; ===== STATE DETECTION =====
DetectState() {
    global LAST_DETECTED_STATE, LAST_STATE_STREAK, REQUIRED_STATE_STREAK

    detection := DetectStateDetailed()
    state := detection.state

    if (state = "Unknown") {
        ; Unknown is treated as a transient read. Keep last stable streak so
        ; one noisy frame does not force extra Unknown cycles.
        return state
    }
    if (state = "Error") {
        LAST_DETECTED_STATE := ""
        LAST_STATE_STREAK := 0
        return state
    }

    if (state = LAST_DETECTED_STATE) {
        LAST_STATE_STREAK++
    } else {
        LAST_DETECTED_STATE := state
        LAST_STATE_STREAK := 1
    }

    if (LAST_STATE_STREAK < REQUIRED_STATE_STREAK) {
        return "Unknown"
    }

    return state
}

DetectStateDetailed() {
    global DETECTION_RETRY_COUNT

    best := {state: "Unknown", score: 0.0, source: "", text: ""}

    loop DETECTION_RETRY_COUNT {
        cycleCheck := CheckConfirmCycle()
        if (cycleCheck.state = "Confirm Cycle") {
            return cycleCheck
        }
        if (cycleCheck.score > best.score) {
            best := cycleCheck
        }

        selectionCheck := CheckConfirmSelection()
        if (selectionCheck.state = "Confirm Selection") {
            return selectionCheck
        }
        if (selectionCheck.score > best.score) {
            best := selectionCheck
        }

        mainCheck := CheckMainState()
        if (mainCheck.state = "Cycle" || mainCheck.state = "Selection") {
            if (mainCheck.score > best.score) {
                best := mainCheck
            }
        } else if (mainCheck.score > best.score) {
            best := mainCheck
        }

        Sleep 60
    }

    return best
}

CheckMainState() {
    textResult := ReadStateText("main", {lang: "en", scale: 1.15, grayscale: 1})
    if (!textResult.ok) {
        return {state: "Error", score: 0.0, source: "main", text: ""}
    }

    classified := ClassifyMainStateText(textResult.text)
    classified.source := "main"
    classified.text := textResult.text
    return classified
}

CheckConfirmCycle() {
    textResult := ReadStateText("confirmCycle", {lang: "en", scale: 1.2, grayscale: 1})
    if (!textResult.ok) {
        return {state: "Error", score: 0.0, source: "confirmCycle", text: ""}
    }

    classified := ClassifyConfirmCycleText(textResult.text)
    classified.source := "confirmCycle"
    classified.text := textResult.text
    return classified
}

CheckConfirmSelection() {
    textResult := ReadStateText("confirmSelection", {lang: "en", scale: 1.2, grayscale: 1})
    if (!textResult.ok) {
        return {state: "Error", score: 0.0, source: "confirmSelection", text: ""}
    }

    classified := ClassifyConfirmSelectionText(textResult.text)
    classified.source := "confirmSelection"
    classified.text := textResult.text
    return classified
}

ReadStateText(areaName, ocrOptions) {
    area := GetStateArea(areaName)
    width := area.x2 - area.x1
    height := area.y2 - area.y1

    try {
        ocrResult := OCR.FromRect(area.x1, area.y1, width, height, ocrOptions)
        text := NormalizeStateText(ocrResult.Text)
        return {ok: true, text: text}
    } catch {
        return {ok: false, text: ""}
    }
}

ClassifyMainStateText(text) {
    normalized := NormalizeStateText(text)
    if (normalized = "") {
        return {state: "Unknown", score: 0.0}
    }

    cycleScore := ScoreKeywordSet(normalized, ["cycle", "for", "kuva"])
    if (InStr(normalized, "cycle for")) {
        cycleScore := Max(cycleScore, 0.95)
    }

    selectionScore := ScoreKeywordSet(normalized, ["confirm", "selection", "riven"])
    if (InStr(normalized, "confirm")) {
        selectionScore := Max(selectionScore, 0.6)
    }

    if (cycleScore >= 0.7 && cycleScore >= selectionScore) {
        return {state: "Cycle", score: cycleScore}
    }
    if (selectionScore >= 0.6) {
        return {state: "Selection", score: selectionScore}
    }

    return {state: "Unknown", score: Max(cycleScore, selectionScore)}
}

ClassifyConfirmCycleText(text) {
    normalized := NormalizeStateText(text)
    if (normalized = "") {
        return {state: "Unknown", score: 0.0}
    }

    score := ScoreKeywordSet(normalized, ["are", "you", "sure", "want", "cycle", "riven"])
    if (InStr(normalized, "are you sure")) {
        score := Max(score, 0.8)
    }
    if (InStr(normalized, "want to cycle")) {
        score := Max(score, 0.9)
    }

    if (score >= 0.72) {
        return {state: "Confirm Cycle", score: score}
    }
    return {state: "Unknown", score: score}
}

ClassifyConfirmSelectionText(text) {
    normalized := NormalizeStateText(text)
    if (normalized = "") {
        return {state: "Unknown", score: 0.0}
    }

    score := ScoreKeywordSet(normalized, ["cycle", "riven", "into", "current", "selection"])
    if (InStr(normalized, "current selection")) {
        score := Max(score, 0.85)
    }
    if (InStr(normalized, "cycle") && InStr(normalized, "riven")) {
        score := Max(score, 0.7)
    }

    if (score >= 0.68) {
        return {state: "Confirm Selection", score: score}
    }
    return {state: "Unknown", score: score}
}

NormalizeStateText(text) {
    normalized := StrLower(text)
    normalized := RegExReplace(normalized, "[^a-z0-9\s]+", " ")
    normalized := Trim(RegExReplace(normalized, "\s+", " "))
    return normalized
}

ScoreKeywordSet(text, keywords) {
    if (text = "") {
        return 0.0
    }

    matches := 0
    for keyword in keywords {
        if (InStr(text, keyword)) {
            matches++
        }
    }

    return matches / keywords.Length
}
