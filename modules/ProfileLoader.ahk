; ===== PROFILE LOADING =====
SelectAndLoadProfile(showResultMessage := true) {
    profilePath := FileSelect(1, A_ScriptDir, "Select Riven Config Profile", "JSON (*.json)")
    if (profilePath = "") {
        return false
    }
    return LoadProfileFromFile(profilePath, showResultMessage)
}

TryAutoLoadLastProfile() {
    global LAST_PROFILE_PATH, RELEASE_BUILD
    if (RELEASE_BUILD) {
        return false
    }
    if (LAST_PROFILE_PATH = "") {
        return false
    }

    if (!FileExist(LAST_PROFILE_PATH)) {
        LogEvent("WARN", "LastProfileMissing", {path: LAST_PROFILE_PATH})
        return false
    }

    return LoadProfileFromFile(LAST_PROFILE_PATH, false)
}

LoadProfileFromFile(profilePath, showResultMessage := true) {
    global ACTIVE_PROFILE, ACTIVE_RULES, REROLL_ENABLED, LAST_PROFILE_PATH, RELEASE_BUILD, JSON_PARSER

    if (!FileExist(profilePath)) {
        MsgBox("Profile file not found:`n" . profilePath, "Profile Error")
        LogEvent("ERROR", "ProfileLoadFailed", {reason: "FileNotFound", path: profilePath})
        return false
    }

    try {
        jsonText := FileRead(profilePath, "UTF-8")
    } catch as err {
        MsgBox("Could not read profile file:`n" . err.Message, "Profile Error")
        LogEvent("ERROR", "ProfileLoadFailed", {reason: "ReadError", message: err.Message, path: profilePath})
        return false
    }

    try {
        bundle := JSON_PARSER.Parse(jsonText)
    } catch as err {
        MsgBox("Invalid JSON profile:`n" . err.Message, "Profile Error")
        LogEvent("ERROR", "ProfileLoadFailed", {reason: "InvalidJson", message: err.Message, path: profilePath})
        return false
    }

    validation := ValidateConfigBundle(bundle)
    if (!validation.ok) {
        MsgBox("Invalid profile format:`n" . validation.message, "Profile Error")
        LogEvent("ERROR", "ProfileLoadFailed", {reason: "InvalidSchema", message: validation.message, path: profilePath})
        return false
    }

    normalizedRules := NormalizeRuleSet(bundle.profile.rules)
    ACTIVE_PROFILE := {
        schemaVersion: bundle.schemaVersion,
        appVersion: bundle.appVersion,
        weaponsCatalogVersion: bundle.weaponsCatalogVersion,
        weaponId: bundle.weaponId,
        weaponName: bundle.weaponName,
        profileId: bundle.profile.id,
        profileName: bundle.profile.name,
        profileDescription: bundle.profile.HasOwnProp("description") ? bundle.profile.description : "",
        rules: normalizedRules,
        sourcePath: profilePath
    }
    ACTIVE_RULES := normalizedRules
    REROLL_ENABLED := true
    LAST_PROFILE_PATH := profilePath
    if (!RELEASE_BUILD) {
        SaveLastProfilePath(profilePath)
    }

    LogEvent("INFO", "ProfileLoaded", {
        profileName: ACTIVE_PROFILE.profileName,
        profileId: ACTIVE_PROFILE.profileId,
        weaponName: ACTIVE_PROFILE.weaponName,
        path: profilePath
    })

    if (showResultMessage) {
        ShowProfileOverviewDialog("Profile Ready")
    }

    return true
}

ValidateConfigBundle(bundle) {
    if (!IsObject(bundle)) {
        return {ok: false, message: "JSON root must be an object."}
    }

    requiredRoot := ["schemaVersion", "appVersion", "weaponsCatalogVersion", "weaponId", "weaponName", "profile"]
    for key in requiredRoot {
        if (!bundle.HasOwnProp(key)) {
            return {ok: false, message: "Missing root property: " . key}
        }
    }

    if (bundle.schemaVersion != "1.0.0") {
        return {ok: false, message: "Unsupported schemaVersion: " . bundle.schemaVersion}
    }

    if (!IsObject(bundle.profile)) {
        return {ok: false, message: "Property 'profile' must be an object."}
    }

    profileRequired := ["id", "name", "rules", "createdAt", "updatedAt"]
    for key in profileRequired {
        if (!bundle.profile.HasOwnProp(key)) {
            return {ok: false, message: "Missing profile property: " . key}
        }
    }

    if (!IsObject(bundle.profile.rules)) {
        return {ok: false, message: "Profile 'rules' must be an object."}
    }

    if (!bundle.profile.rules.HasOwnProp("positiveSlots") || !bundle.profile.rules.HasOwnProp("negativeSlot")) {
        return {ok: false, message: "Rules must include positiveSlots and negativeSlot."}
    }

    positiveSlots := bundle.profile.rules.positiveSlots
    if (Type(positiveSlots) != "Array" || positiveSlots.Length != 3) {
        return {ok: false, message: "positiveSlots must be an array of exactly 3 slots."}
    }

    for index, slot in positiveSlots {
        slotValidation := ValidateRuleSlot(slot, "positiveSlots[" . index . "]")
        if (!slotValidation.ok) {
            return slotValidation
        }
    }
    if (positiveSlots[1].mode = "undesired") {
        return {ok: false, message: "positiveSlots[1] cannot use mode: undesired"}
    }
    if (positiveSlots[2].mode = "undesired") {
        return {ok: false, message: "positiveSlots[2] cannot use mode: undesired"}
    }

    negativeValidation := ValidateRuleSlot(bundle.profile.rules.negativeSlot, "negativeSlot")
    if (!negativeValidation.ok) {
        return negativeValidation
    }

    return {ok: true, message: ""}
}

ValidateRuleSlot(slot, path) {
    global ATTRIBUTE_ID_TO_LABEL

    if (!IsObject(slot)) {
        return {ok: false, message: path . " must be an object."}
    }

    if (!slot.HasOwnProp("mode")) {
        return {ok: false, message: path . " missing 'mode'."}
    }
    if (!slot.HasOwnProp("attrIds")) {
        return {ok: false, message: path . " missing 'attrIds'."}
    }

    validModes := Map("mandatory", true, "desired", true, "indifferent", true, "undesired", true)
    if (!validModes.Has(slot.mode)) {
        return {ok: false, message: path . " has invalid mode: " . slot.mode}
    }

    if (Type(slot.attrIds) != "Array") {
        return {ok: false, message: path . ".attrIds must be an array."}
    }

    if ((slot.mode = "mandatory" || slot.mode = "desired") && slot.attrIds.Length = 0) {
        return {ok: false, message: path . ".attrIds must not be empty for mode: " . slot.mode}
    }
    if (slot.mode = "indifferent" || slot.mode = "undesired") {
        return {ok: true, message: ""}
    }

    for index, attrId in slot.attrIds {
        if (Type(attrId) != "String" || Trim(attrId) = "") {
            return {ok: false, message: path . ".attrIds[" . index . "] must be a non-empty string."}
        }
        if (!ATTRIBUTE_ID_TO_LABEL.Has(attrId)) {
            return {ok: false, message: path . ".attrIds[" . index . "] has unknown attribute id: " . attrId}
        }
    }

    return {ok: true, message: ""}
}

NormalizeRuleSet(rules) {
    normalizedPositives := []
    for slot in rules.positiveSlots {
        normalizedPositives.Push(NormalizeRuleSlot(slot))
    }

    return {
        positiveSlots: normalizedPositives,
        negativeSlot: NormalizeRuleSlot(rules.negativeSlot)
    }
}

NormalizeRuleSlot(slot) {
    if (slot.mode = "indifferent" || slot.mode = "undesired") {
        return {
            mode: slot.mode,
            attrIds: []
        }
    }

    uniqueIds := []
    seen := Map()
    for attrId in slot.attrIds {
        if (!seen.Has(attrId)) {
            uniqueIds.Push(attrId)
            seen[attrId] := true
        }
    }

    return {
        mode: slot.mode,
        attrIds: uniqueIds
    }
}

ShowProfileOverviewDialog(title := "Riven Reroller Ready") {
    loop {
        action := ShowSingleProfileOverviewDialog(title)
        if (action != "changeProfile") {
            return action
        }
        SelectAndLoadProfile(false)
    }
}

ShowSingleProfileOverviewDialog(title) {
    global ACTIVE_RULES, RELEASE_BUILD, MAX_CYCLES

    result := "ok"
    panelWidth := 372
    panelHeight := 146
    panelGap := 16
    releaseMode := RELEASE_BUILD ? true : false

    overviewGui := Gui("+AlwaysOnTop +OwnDialogs", title)
    overviewGui.BackColor := "F3F6F9"
    overviewGui.MarginX := 18
    overviewGui.MarginY := 16

    overviewGui.SetFont("s15 w700", "Segoe UI")
    overviewGui.Add("Text", "xm w760 c203040", title)

    overviewGui.SetFont("s10 c505C68", "Segoe UI")
    overviewGui.Add("Text", "xm y+6 w760", "Confirm the active profile, reroll limit, and hotkeys before starting.")

    overviewGui.SetFont("s10", "Segoe UI")
    profileGroup := overviewGui.Add("GroupBox", "xm y+14 w760 h124", "Active Profile")
    profileGroup.GetPos(&profileX, &profileY, &profileW, &profileH)
    overviewGui.Add("Edit", "x" . (profileX + 14) . " y" . (profileY + 24) . " w730 h82 ReadOnly -Wrap", BuildCurrentProfileSummary())

    ruleLeftX := profileX
    ruleRightX := profileX + panelWidth + panelGap
    ruleTopY := profileY + profileH + 12
    ruleBottomY := ruleTopY + panelHeight + 12

    AddRulePanel(overviewGui, ruleLeftX, ruleTopY, panelWidth, panelHeight, "Positive Slot 1", GetRuleSlotForOverview("positive", 1))
    AddRulePanel(overviewGui, ruleRightX, ruleTopY, panelWidth, panelHeight, "Positive Slot 2", GetRuleSlotForOverview("positive", 2))
    AddRulePanel(overviewGui, ruleLeftX, ruleBottomY, panelWidth, panelHeight, "Positive Slot 3", GetRuleSlotForOverview("positive", 3))
    AddRulePanel(overviewGui, ruleRightX, ruleBottomY, panelWidth, panelHeight, "Negative Slot", GetRuleSlotForOverview("negative"))

    hotkeyTopY := ruleBottomY + panelHeight + 12
    mainHotkeysWidth := releaseMode ? 760 : 372
    overviewGui.Add("GroupBox", "x" . ruleLeftX . " y" . hotkeyTopY . " w" . mainHotkeysWidth . " h154", "Main Hotkeys")
    overviewGui.SetFont("s10", "Consolas")
    overviewGui.Add("Text", "x" . (ruleLeftX + 16) . " y" . (hotkeyTopY + 26) . " w" . (mainHotkeysWidth - 32) . " c1F2933", BuildMainHotkeySummary())

    if (!releaseMode) {
        overviewGui.SetFont("s10", "Segoe UI")
        overviewGui.Add("GroupBox", "x" . ruleRightX . " y" . hotkeyTopY . " w372 h154", "Testing Hotkeys")
        overviewGui.SetFont("s10", "Consolas")
        overviewGui.Add("Text", "x" . (ruleRightX + 16) . " y" . (hotkeyTopY + 26) . " w340 c1F2933", BuildTestingHotkeySummary())
    }

    overviewGui.SetFont("s10", "Segoe UI")
    buttonY := hotkeyTopY + 154 + 20
    changeButton := overviewGui.Add("Button", "x" . profileX . " y" . buttonY . " w150 h34", "Change profile")
    okButton := overviewGui.Add("Button", "x" . (profileX + 162) . " y" . buttonY . " w110 h34 Default", "OK")
    rerollLabelX := profileX + 288
    overviewGui.Add("Text", "x" . rerollLabelX . " y" . (buttonY + 8) . " w112 c203040", "Maximum rerolls")
    maxCyclesEdit := overviewGui.Add("Edit", "x" . (rerollLabelX + 120) . " y" . buttonY . " w96 Number", MAX_CYCLES)
    overviewGui.Add("UpDown", "Range1-999999", MAX_CYCLES)

    changeButton.OnEvent("Click", OnChangeProfile)
    okButton.OnEvent("Click", OnOk)
    overviewGui.OnEvent("Close", OnOk)
    overviewGui.OnEvent("Escape", OnOk)

    overviewGui.Show("AutoSize Center")
    WinWaitClose("ahk_id " . overviewGui.Hwnd)
    return result

    OnChangeProfile(*) {
        if (!ApplySessionSettings()) {
            return
        }
        result := "changeProfile"
        overviewGui.Destroy()
    }

    OnOk(*) {
        if (!ApplySessionSettings()) {
            return
        }
        result := "ok"
        overviewGui.Destroy()
    }

    ApplySessionSettings() {
        global MAX_CYCLES

        if (!TryParseMaxCyclesValue(maxCyclesEdit.Value, &parsedMaxCycles, &errorMessage)) {
            MsgBox(errorMessage, "Session Settings")
            maxCyclesEdit.Focus()
            return false
        }

        MAX_CYCLES := parsedMaxCycles
        return true
    }
}

AddRulePanel(overviewGui, x, y, width, height, panelTitle, slot) {
    modeColor := GetRuleModeColor(slot.mode)

    overviewGui.SetFont("s10", "Segoe UI")
    overviewGui.Add("GroupBox", "x" . x . " y" . y . " w" . width . " h" . height, panelTitle)

    overviewGui.SetFont("s10 w700 c" . modeColor, "Segoe UI")
    overviewGui.Add("Text", "x" . (x + 14) . " y" . (y + 24) . " w" . (width - 28), FormatRuleModeLabel(slot.mode))

    overviewGui.SetFont("s9 c202B36", "Segoe UI")
    overviewGui.Add("Edit", "x" . (x + 14) . " y" . (y + 48) . " w" . (width - 28) . " h84 ReadOnly -Wrap VScroll", FormatRuleAttrList(slot))
}

GetRuleSlotForOverview(slotType, index := 0) {
    global ACTIVE_RULES

    defaultSlot := {mode: "indifferent", attrIds: []}
    if (!IsObject(ACTIVE_RULES) || !ACTIVE_RULES.HasOwnProp("positiveSlots") || !ACTIVE_RULES.HasOwnProp("negativeSlot")) {
        return defaultSlot
    }

    if (slotType = "negative") {
        return ACTIVE_RULES.negativeSlot
    }

    if (index >= 1 && index <= ACTIVE_RULES.positiveSlots.Length) {
        return ACTIVE_RULES.positiveSlots[index]
    }

    return defaultSlot
}

BuildCurrentProfileSummary() {
    global ACTIVE_PROFILE

    lines := []

    if (ACTIVE_PROFILE.HasOwnProp("profileName")) {
        lines.Push("Name: " . ACTIVE_PROFILE.profileName)
        lines.Push("Weapon: " . ACTIVE_PROFILE.weaponName)
        lines.Push("File:")
        lines.Push("  " . ACTIVE_PROFILE.sourcePath)
    } else {
        lines.Push("Name: No profile loaded")
        lines.Push("Weapon: n/a")
    }

    return JoinProfileOverviewLines(lines)
}

TryParseMaxCyclesValue(rawValue, &parsedValue, &errorMessage := "") {
    rawText := Trim(rawValue)
    parsedValue := 0

    if (rawText = "") {
        errorMessage := "Maximum rerolls must be a whole number between 1 and 999999."
        return false
    }
    if (!RegExMatch(rawText, "^\d+$")) {
        errorMessage := "Maximum rerolls must contain digits only."
        return false
    }

    parsedValue := rawText + 0
    if (parsedValue < 1 || parsedValue > 999999) {
        errorMessage := "Maximum rerolls must be between 1 and 999999."
        return false
    }

    errorMessage := ""
    return true
}

FormatRuleModeLabel(mode) {
    switch mode {
        case "mandatory":
            return "Mandatory"
        case "desired":
            return "Desired"
        case "undesired":
            return "Undesired"
        case "indifferent":
            return "Indifferent"
        default:
            return mode
    }
}

GetRuleModeColor(mode) {
    switch mode {
        case "mandatory":
            return "7C3AED"
        case "desired":
            return "15803D"
        case "indifferent":
            return "6B7280"
        case "undesired":
            return "B91C1C"
        default:
            return "202B36"
    }
}

BuildMainHotkeySummary() {
    global RELEASE_BUILD
    lines := []
    lines.Push("F8   Load/change JSON profile")
    lines.Push("F9   Start reroll loop")
    lines.Push("F10  Stop reroll loop")
    if (!RELEASE_BUILD) {
        lines.Push("F11  Show current riven evaluation")
        lines.Push("F6   Run unit tests")
    }
    lines.Push("Esc  Exit app")
    return JoinProfileOverviewLines(lines)
}

BuildTestingHotkeySummary() {
    lines := []
    lines.Push("F1   Test main state detection")
    lines.Push("F2   Test confirm cycle detection")
    lines.Push("F3   Test confirm selection detection")
    lines.Push("F4   Test complete state detection")
    lines.Push("F5   Show OCR/state overlay areas")
    return JoinProfileOverviewLines(lines)
}

FormatRuleAttrList(slot) {
    global ATTRIBUTE_ID_TO_LABEL

    attrIds := slot.attrIds
    if (slot.mode = "undesired") {
        return "  (slot must be empty)"
    }

    if (attrIds.Length = 0) {
        return "  (none)"
    }

    labels := []
    for attrId in attrIds {
        label := ATTRIBUTE_ID_TO_LABEL.Has(attrId) ? ATTRIBUTE_ID_TO_LABEL[attrId] : attrId
        labels.Push("  - " . label)
    }
    return JoinProfileOverviewLines(labels)
}

JoinProfileOverviewLines(lines, separator := "`n") {
    out := ""
    for index, line in lines {
        if (index > 1) {
            out .= separator
        }
        out .= line
    }
    return out
}
