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
global HUMAN_MOUSE_ENABLED := true
global HUMAN_MOUSE_MIN_DURATION_MS := 110
global HUMAN_MOUSE_MAX_DURATION_MS := 320
global HUMAN_MOUSE_MS_PER_PIXEL := 0.22
global HUMAN_MOUSE_PIXELS_PER_STEP := 38
global HUMAN_MOUSE_MIN_STEPS := 6
global HUMAN_MOUSE_MAX_STEPS := 16
global HUMAN_MOUSE_CURVE_STRENGTH := 0.10
global HUMAN_MOUSE_CURVE_MAX_OFFSET_PX := 60
global HUMAN_MOUSE_OVERSHOOT_CHANCE := 0.35
global HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE := 140
global HUMAN_MOUSE_OVERSHOOT_MIN_PX := 6
global HUMAN_MOUSE_OVERSHOOT_MAX_PX := 22
global HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX := 4
global HUMAN_MOUSE_OVERSHOOT_CLICK_CHANCE := 0.08
global HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MIN_MS := 45
global HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MAX_MS := 180
global HUMAN_MOUSE_OVERSHOOT_CORRECTION_MIN_MS := 30
global HUMAN_MOUSE_OVERSHOOT_CORRECTION_MAX_MS := 90
global HUMAN_MOUSE_IDLE_DURING_SLEEP := true
global HUMAN_MOUSE_IDLE_SLEEP_CHANCE := 0.65
global HUMAN_MOUSE_IDLE_SLEEP_MIN_DELAY_MS := 260
global HUMAN_MOUSE_IDLE_SLEEP_MAX_MOVES := 2
global HUMAN_MOUSE_IDLE_SLEEP_PAUSE_MIN_MS := 80
global HUMAN_MOUSE_IDLE_SLEEP_PAUSE_MAX_MS := 480
global HUMAN_MOUSE_IDLE_MOVE_BUFFER_MS := 170
global HUMAN_MOUSE_IDLE_NEAR_MOVE_CHANCE := 0.65
global HUMAN_MOUSE_IDLE_NEAR_MIN_PX := 8
global HUMAN_MOUSE_IDLE_NEAR_MAX_PX := 40
global HUMAN_MOUSE_IDLE_FAR_MIN_PX := 45
global HUMAN_MOUSE_IDLE_FAR_MAX_PX := 170
global HUMAN_MOUSE_IDLE_FAST_MOVE_CHANCE := 0.45
global HUMAN_MOUSE_IDLE_FAST_SPEED_MIN := 0.55
global HUMAN_MOUSE_IDLE_FAST_SPEED_MAX := 0.90
global HUMAN_MOUSE_IDLE_SLOW_SPEED_MIN := 1.15
global HUMAN_MOUSE_IDLE_SLOW_SPEED_MAX := 1.75
; Safe key list assumes a US keyboard layout for punctuation keys.
global SAFE_KEYSTROKE_ENABLED := true
global SAFE_KEYSTROKE_PRESS_CHANCE := 0.10
global SAFE_KEYSTROKE_MIN_DELAY_MS := 220
global SAFE_KEYSTROKE_MAX_PRESSES_PER_SLEEP := 1
global SAFE_KEYSTROKE_HOLD_MIN_MS := 25
global SAFE_KEYSTROKE_HOLD_MAX_MS := 110
global SAFE_KEYSTROKE_POST_PRESS_MIN_MS := 35
global SAFE_KEYSTROKE_POST_PRESS_MAX_MS := 120
global SAFE_KEYSTROKES := [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "``", "-", "=", "[", "]", "\", ";", "'", ",", ".", "/",
    "{Shift}", "{Ctrl}", "{Alt}",
    "{Up}", "{Down}", "{Left}", "{Right}"
]
global HUMAN_LONG_WAIT_ENABLED := true
global HUMAN_LONG_WAIT_PRE_CYCLE_CHANCE := 0.10
global HUMAN_LONG_WAIT_PRE_CYCLE_MIN_MS := 1800
global HUMAN_LONG_WAIT_PRE_CYCLE_MAX_MS := 5200
global HUMAN_LONG_WAIT_PRE_KEEP_CHANCE := 0.14
global HUMAN_LONG_WAIT_PRE_KEEP_MIN_MS := 1500
global HUMAN_LONG_WAIT_PRE_KEEP_MAX_MS := 4200
global HUMAN_MOUSE_DURATION_JITTER_PERCENT := 0.18
global HUMAN_MOUSE_STEP_DELAY_JITTER_PERCENT := 0.25
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
    global JSON_PARSER

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
            profile := JSON_PARSER.Parse(profileRaw)
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

ClampNumber(value, minValue, maxValue) {
    return Min(Max(value, minValue), maxValue)
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
