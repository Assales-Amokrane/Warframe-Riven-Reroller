; ===== STATE DETECTION TESTING =====

; Test main state detection
F1:: {
    detection := CheckMainState()
    area := GetStateArea("main")

    try {
        ocrResult := OCR.FromRect(area.x1, area.y1, area.x2 - area.x1, area.y2 - area.y1, "en")
        rawText := ocrResult.Text
    } catch {
        rawText := "ERROR"
    }
    
    MsgBox(
        "=== MAIN STATE TEST ===`n`n" .
        "Detected State: " . detection.state . "`n" .
        "Confidence: " . detection.score . "`n`n" .
        "OCR Text:`n" . rawText . "`n`n" .
        "Area: " . area.x1 . ", " . area.y1 . " to " . area.x2 . ", " . area.y2,
        "Main State Test"
    )
}

; Test confirm cycle state detection
F2:: {
    detection := CheckConfirmCycle()
    area := GetStateArea("confirmCycle")

    try {
        ocrResult := OCR.FromRect(area.x1, area.y1, area.x2 - area.x1, area.y2 - area.y1, "en")
        rawText := ocrResult.Text
    } catch {
        rawText := "ERROR"
    }

    result := (detection.state = "Confirm Cycle") ? "DETECTED" : "NOT DETECTED"
    
    MsgBox(
        "=== CONFIRM CYCLE STATE TEST ===`n`n" .
        "Result: " . result . "`n`n" .
        "Confidence: " . detection.score . "`n`n" .
        "OCR Text:`n" . rawText . "`n`n" .
        "Area: " . area.x1 . ", " . area.y1 . " to " . area.x2 . ", " . area.y2,
        "Confirm Cycle Test"
    )
}

; Test confirm selection state detection
F3:: {
    detection := CheckConfirmSelection()
    area := GetStateArea("confirmSelection")

    try {
        ocrResult := OCR.FromRect(area.x1, area.y1, area.x2 - area.x1, area.y2 - area.y1, "en")
        rawText := ocrResult.Text
    } catch {
        rawText := "ERROR"
    }

    result := (detection.state = "Confirm Selection") ? "DETECTED" : "NOT DETECTED"
    
    MsgBox(
        "=== CONFIRM SELECTION STATE TEST ===`n`n" .
        "Result: " . result . "`n`n" .
        "Confidence: " . detection.score . "`n`n" .
        "OCR Text:`n" . rawText . "`n`n" .
        "Area: " . area.x1 . ", " . area.y1 . " to " . area.x2 . ", " . area.y2,
        "Confirm Selection Test"
    )
}

; Test complete state detection (what DetectState() returns)
F4:: {
    state := DetectState()
    
    ; Get all OCR results
    mainText := "N/A"
    confirmCycleText := "N/A"
    confirmSelectionText := "N/A"
    
    try {
        area := GetStateArea("main")
        ocrResult := OCR.FromRect(area.x1, area.y1, area.x2 - area.x1, area.y2 - area.y1, "en")
        mainText := ocrResult.Text
    } catch {
        mainText := "ERROR"
    }
    
    try {
        area := GetStateArea("confirmCycle")
        ocrResult := OCR.FromRect(area.x1, area.y1, area.x2 - area.x1, area.y2 - area.y1, "en")
        confirmCycleText := ocrResult.Text
    } catch {
        confirmCycleText := "ERROR"
    }
    
    try {
        area := GetStateArea("confirmSelection")
        ocrResult := OCR.FromRect(area.x1, area.y1, area.x2 - area.x1, area.y2 - area.y1, "en")
        confirmSelectionText := ocrResult.Text
    } catch {
        confirmSelectionText := "ERROR"
    }
    
    MsgBox(
        "=== COMPLETE STATE DETECTION TEST ===`n`n" .
        "FINAL STATE: " . state . "`n`n" .
        "--- Main Area ---`n" . mainText . "`n`n" .
        "--- Confirm Cycle Area ---`n" . confirmCycleText . "`n`n" .
        "--- Confirm Selection Area ---`n" . confirmSelectionText,
        "Complete State Test",
        "T10"
    )
}

; Show all detection areas with colored overlays
F5:: {
    overlays := []
    
    ; Main area - RED
    area := GetStateArea("main")
    overlay := Gui("+AlwaysOnTop +ToolWindow -Caption +E0x20")
    overlay.BackColor := "Red"
    WinSetTransparent(100, overlay)
    overlay.Show("x" . area.x1 . " y" . area.y1 . " w" . (area.x2 - area.x1) . " h" . (area.y2 - area.y1) . " NA")
    overlays.Push(overlay)
    
    ; Confirm Cycle area - GREEN
    area := GetStateArea("confirmCycle")
    overlay := Gui("+AlwaysOnTop +ToolWindow -Caption +E0x20")
    overlay.BackColor := "Green"
    WinSetTransparent(100, overlay)
    overlay.Show("x" . area.x1 . " y" . area.y1 . " w" . (area.x2 - area.x1) . " h" . (area.y2 - area.y1) . " NA")
    overlays.Push(overlay)
    
    ; Confirm Selection area - BLUE
    area := GetStateArea("confirmSelection")
    overlay := Gui("+AlwaysOnTop +ToolWindow -Caption +E0x20")
    overlay.BackColor := "Blue"
    WinSetTransparent(100, overlay)
    overlay.Show("x" . area.x1 . " y" . area.y1 . " w" . (area.x2 - area.x1) . " h" . (area.y2 - area.y1) . " NA")
    overlays.Push(overlay)
    
    ; Auto-close after 3 seconds
    SetTimer(DestroyOverlays.Bind(overlays), -GetRandomizedDelay(3000, 1))
    
    PrintStatus("RED=Main | GREEN=Confirm Cycle | BLUE=Confirm Selection (3 sec)")
}

DestroyOverlays(overlays) {
    for overlay in overlays {
        overlay.Destroy()
    }
}
