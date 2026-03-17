; ===== RUNTIME CONFIGURATION =====
global RELEASE_BUILD
global REROLL_ENABLED := false
global IS_RUNNING := false
global CURRENT_CYCLE := 0
global MAX_CYCLES := 100
global ACTION_DELAY := 3000
global START_CYCLE_TO_CONFIRM_DELAY := 2000
global START_SELECTION_TO_CONFIRM_DELAY := 2000
global POST_CONFIRM_SELECTION_DELAY := 2000
global TIMER_JITTER_PERCENT := 0.10
global CLICK_POSITION_JITTER_PX := 5
global REROLL_TICK_DELAY := 100

global OLD_RIVEN := {}
global NEW_RIVEN := {}
global STOP_AFTER_CONFIRM := false
global STOP_REASON_AFTER_CONFIRM := ""

global ACTIVE_PROFILE := {}
global ACTIVE_RULES := {}
global LAST_PROFILE_PATH := ""

global LAST_DETECTED_STATE := ""
global LAST_STATE_STREAK := 0
global LAST_LOGGED_REROLL_STATE := ""
global UNKNOWN_REROLL_STATE_STREAK := 0
global LAST_REROLL_STATUS_LINE := ""
global REQUIRED_STATE_STREAK := 2
global DETECTION_RETRY_COUNT := 2
global UNKNOWN_STATE_DELAY := 300
global UNKNOWN_STATE_DELAY_FAST := 90
global UNKNOWN_SLOW_DELAY_STREAK := 5
global UNKNOWN_STATUS_STREAK := 2

global RUN_LOG_FILE := ""
global LOG_DIR := A_ScriptDir "\logs"
global LOG_VERBOSE_OCR := true
global PRINT_STATUS_TO_CONSOLE := true
global OCR_MIN_INDEPENDENT_READS := 3
global OCR_BRIGHTNESS_BOOST := 24
global OCR_SHARPEN_ENABLED := true
global LOG_STATE_CHANGE_ONLY := true
global LOG_UNKNOWN_STATES := false
global UNKNOWN_LOG_STREAK := 3
global CAPTURE_NEW_RIVEN_READS := true
global ATTRIBUTE_CAPTURE_DIR := LOG_DIR "\attribute-captures"

global SETTINGS_DIR := A_ScriptDir "\config"
global LAST_PROFILE_FILE := SETTINGS_DIR "\last-profile.txt"
global COORDINATE_PROFILE_FILE := SETTINGS_DIR "\coordinate-profile.json"

; ===== COORDINATES (BASE 1920x1080) =====
global BASE_RESOLUTION := {w: 1920, h: 1080}
global BASE_STATE_AREAS := {
    main: {x1: 720, y1: 910, x2: 1210, y2: 1035},
    confirmCycle: {x1: 690, y1: 455, x2: 1230, y2: 550},
    confirmSelection: {x1: 750, y1: 475, x2: 1200, y2: 525}
}
global BASE_ACTION_COORDS := {
    startCycle: {x: 1050, y: 960},
    confirmCycleStart: {x: 835, y: 590},
    rivenAttributes: {x1: 820, y1: 635, x2: 1105, y2: 830},
    pickOldRiven: {x: 790, y: 670},
    startSelection: {x: 1050, y: 960},
    confirmSelection: {x: 835, y: 590}
}

global STATE_AREAS := {}
global ACTION_COORDS := {}

global SCALE_X := 1.0
global SCALE_Y := 1.0
global COORD_OFFSET_X := 0
global COORD_OFFSET_Y := 0

; ===== ATTRIBUTE CATALOG (must match configurator IDs) =====
global ATTRIBUTE_LABELS := [
    "Puncture",
    "Impact",
    "Slash",
    "Electricity",
    "Heat",
    "Cold",
    "Toxin",
    "Damage to Corpus",
    "Damage to Grineer",
    "Damage to Infested",
    "Critical Damage",
    "Status Chance",
    "Status Duration",
    "Fire Rate (x2 for Bows)",
    "Critical Chance",
    "Multishot",
    "Punch Through",
    "Damage",
    "Range",
    "Critical Chance for Slide Attack",
    "Critical Chance (x2 for Heavy Attacks)",
    "Finisher Damage",
    "Attack Speed",
    "Melee Damage",
    "Weapon Recoil",
    "Zoom",
    "Ammo Maximum",
    "Reload Speed",
    "Projectile Speed",
    "Magazine Capacity",
    "Additional Combo Count Chance",
    "Initial Combo",
    "Combo Duration",
    "Heavy Attack Efficiency"
]
global ATTRIBUTE_ID_TO_LABEL := Map()
global ATTRIBUTE_LABEL_TO_ID := Map()

InitializeRuntimeConfig() {
    global SETTINGS_DIR, LAST_PROFILE_PATH, LOG_DIR, ATTRIBUTE_CAPTURE_DIR, RELEASE_BUILD
    ApplyBuildModeDefaults()
    if (!RELEASE_BUILD) {
        EnsureDirectory(SETTINGS_DIR)
        EnsureDirectory(LOG_DIR)
        EnsureDirectory(ATTRIBUTE_CAPTURE_DIR)
    }
    InitializeAttributeCatalog()
    InitializeCoordinateProfile()
    LAST_PROFILE_PATH := RELEASE_BUILD ? "" : LoadLastProfilePath()
}

ApplyBuildModeDefaults() {
    global RELEASE_BUILD, LOG_VERBOSE_OCR, CAPTURE_NEW_RIVEN_READS, LOG_UNKNOWN_STATES

    if (!RELEASE_BUILD) {
        return
    }

    LOG_VERBOSE_OCR := false
    LOG_UNKNOWN_STATES := false
    CAPTURE_NEW_RIVEN_READS := false
}

InitializeAttributeCatalog() {
    global ATTRIBUTE_LABELS, ATTRIBUTE_ID_TO_LABEL, ATTRIBUTE_LABEL_TO_ID

    seenIds := Map()
    for label in ATTRIBUTE_LABELS {
        id := BuildAttributeId(label, seenIds)
        ATTRIBUTE_ID_TO_LABEL[id] := label
        ATTRIBUTE_LABEL_TO_ID[label] := id
    }
}

BuildAttributeId(label, seenIds) {
    baseId := Slugify(label)
    if (!seenIds.Has(baseId)) {
        seenIds[baseId] := 1
        return baseId
    }

    seenIds[baseId] := seenIds[baseId] + 1
    return baseId . "-" . seenIds[baseId]
}

Slugify(input) {
    slug := StrLower(input)
    slug := RegExReplace(slug, "\([^)]*\)", "")
    slug := RegExReplace(slug, "[^a-z0-9]+", "-")
    slug := RegExReplace(slug, "^-+|-+$", "")
    slug := RegExReplace(slug, "-{2,}", "-")
    return slug
}

GetAllAttributeLabels() {
    global ATTRIBUTE_LABELS
    labels := []
    for label in ATTRIBUTE_LABELS {
        labels.Push(label)
    }
    return labels
}

InitializeCoordinateProfile() {
    global BASE_RESOLUTION, BASE_ACTION_COORDS, BASE_STATE_AREAS
    global ACTION_COORDS, STATE_AREAS, SCALE_X, SCALE_Y, COORD_OFFSET_X, COORD_OFFSET_Y, COORDINATE_PROFILE_FILE, RELEASE_BUILD
    global Json

    SCALE_X := A_ScreenWidth / BASE_RESOLUTION.w
    SCALE_Y := A_ScreenHeight / BASE_RESOLUTION.h
    COORD_OFFSET_X := 0
    COORD_OFFSET_Y := 0

    ACTION_COORDS := ScaleActionCoords(BASE_ACTION_COORDS)
    STATE_AREAS := ScaleStateAreas(BASE_STATE_AREAS)

    ; Optional local override profile (can fine-tune coordinates per setup).
    if (!RELEASE_BUILD && FileExist(COORDINATE_PROFILE_FILE)) {
        try {
            profileRaw := FileRead(COORDINATE_PROFILE_FILE, "UTF-8")
            profile := Json.Parse(profileRaw)
            ApplyCoordinateProfile(profile)
        } catch as err {
            ; Do not block startup if local profile is invalid.
        }
    }
}

ScaleActionCoords(baseCoords) {
    scaled := {}
    for key, coords in baseCoords.OwnProps() {
        if (coords.HasOwnProp("x1")) {
            scaled.%key% := ScaleRect(coords)
        } else {
            scaled.%key% := ScalePoint(coords)
        }
    }
    return scaled
}

ScaleStateAreas(baseAreas) {
    scaled := {}
    for key, area in baseAreas.OwnProps() {
        scaled.%key% := ScaleRect(area)
    }
    return scaled
}

ScalePoint(point) {
    global SCALE_X, SCALE_Y, COORD_OFFSET_X, COORD_OFFSET_Y
    return {
        x: Round(point.x * SCALE_X + COORD_OFFSET_X),
        y: Round(point.y * SCALE_Y + COORD_OFFSET_Y)
    }
}

ScaleRect(rect) {
    global SCALE_X, SCALE_Y, COORD_OFFSET_X, COORD_OFFSET_Y
    return {
        x1: Round(rect.x1 * SCALE_X + COORD_OFFSET_X),
        y1: Round(rect.y1 * SCALE_Y + COORD_OFFSET_Y),
        x2: Round(rect.x2 * SCALE_X + COORD_OFFSET_X),
        y2: Round(rect.y2 * SCALE_Y + COORD_OFFSET_Y)
    }
}

ApplyCoordinateProfile(profile) {
    global ACTION_COORDS, STATE_AREAS, SCALE_X, SCALE_Y, COORD_OFFSET_X, COORD_OFFSET_Y
    global BASE_ACTION_COORDS, BASE_STATE_AREAS

    if (profile.HasOwnProp("scaleX")) {
        SCALE_X := profile.scaleX
    }
    if (profile.HasOwnProp("scaleY")) {
        SCALE_Y := profile.scaleY
    }
    if (profile.HasOwnProp("offsetX")) {
        COORD_OFFSET_X := profile.offsetX
    }
    if (profile.HasOwnProp("offsetY")) {
        COORD_OFFSET_Y := profile.offsetY
    }

    ; Re-apply base scaling if scale/offset were overridden.
    ACTION_COORDS := ScaleActionCoords(BASE_ACTION_COORDS)
    STATE_AREAS := ScaleStateAreas(BASE_STATE_AREAS)

    if (profile.HasOwnProp("actionCoords")) {
        for key, value in profile.actionCoords.OwnProps() {
            ACTION_COORDS.%key% := value
        }
    }
    if (profile.HasOwnProp("stateAreas")) {
        for key, value in profile.stateAreas.OwnProps() {
            STATE_AREAS.%key% := value
        }
    }
}

GetStateArea(areaName) {
    global STATE_AREAS
    return STATE_AREAS.%areaName%
}

GetActionCoord(coordName) {
    global ACTION_COORDS
    return ACTION_COORDS.%coordName%
}

GetRandomizedDelay(baseDelay, minimumDelay := 0, jitterPercent := "") {
    global TIMER_JITTER_PERCENT

    percent := (jitterPercent = "") ? TIMER_JITTER_PERCENT : jitterPercent
    adjustedDelay := baseDelay
    if (percent > 0) {
        adjustedDelay := Round(baseDelay * Random(1 - percent, 1 + percent))
    }

    return Max(adjustedDelay, minimumDelay)
}

SleepRandomized(baseDelay, minimumDelay := 0, jitterPercent := "") {
    Sleep(GetRandomizedDelay(baseDelay, minimumDelay, jitterPercent))
}

ApplyRandomClickOffset(basePoint, maxOffset := "") {
    global CLICK_POSITION_JITTER_PX

    offset := (maxOffset = "") ? CLICK_POSITION_JITTER_PX : maxOffset
    if (offset <= 0) {
        return {x: basePoint.x, y: basePoint.y}
    }

    return {
        x: basePoint.x + Random(-offset, offset),
        y: basePoint.y + Random(-offset, offset)
    }
}

SaveLastProfilePath(path) {
    global LAST_PROFILE_FILE, RELEASE_BUILD
    if (RELEASE_BUILD) {
        return
    }
    try {
        FileDelete(LAST_PROFILE_FILE)
    }
    try {
        FileAppend(path, LAST_PROFILE_FILE, "UTF-8")
    }
}

LoadLastProfilePath() {
    global LAST_PROFILE_FILE, RELEASE_BUILD
    if (RELEASE_BUILD) {
        return ""
    }
    if (!FileExist(LAST_PROFILE_FILE)) {
        return ""
    }
    try {
        return Trim(FileRead(LAST_PROFILE_FILE, "UTF-8"))
    }
    return ""
}

EnsureDirectory(path) {
    if (!DirExist(path)) {
        DirCreate(path)
    }
}
