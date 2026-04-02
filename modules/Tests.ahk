; ===== UNIT TESTS =====
RunUnitTests() {
    total := 0
    failed := 0
    failures := []

    RunTest("ParseAttributeLine exact mapping", Func("Test_ParseAttributeLineExact"), &total, &failed, &failures)
    RunTest("ParseAttributeLine OCR shorthand mapping", Func("Test_ParseAttributeLineShorthand"), &total, &failed, &failures)
    RunTest("ParseAttributeLine icon noise mapping", Func("Test_ParseAttributeLineIconNoise"), &total, &failed, &failures)
    RunTest("ParseAttributeLine percent display", Func("Test_ParseAttributeLinePercentDisplay"), &total, &failed, &failures)
    RunTest("ParseAttributeLine multiplier polarity/mapping", Func("Test_ParseAttributeLineMultiplierPolarity"), &total, &failed, &failures)
    RunTest("ParseAttributeLine spaced multiplier decimal", Func("Test_ParseAttributeLineSpacedMultiplierDecimal"), &total, &failed, &failures)
    RunTest("EvaluateCandidate mandatory/desired", Func("Test_EvaluateCandidateMandatoryDesired"), &total, &failed, &failures)
    RunTest("EvaluateCandidate desired negative allow-list", Func("Test_EvaluateCandidateDesiredNegativeAllowList"), &total, &failed, &failures)
    RunTest("EvaluateCandidate undesired positive rejects third positive", Func("Test_EvaluateCandidateUndesiredPositiveReject"), &total, &failed, &failures)
    RunTest("EvaluateCandidate undesired positive keeps two positives", Func("Test_EvaluateCandidateUndesiredPositiveKeep"), &total, &failed, &failures)
    RunTest("EvaluateCandidate undesired negative rejects any negative", Func("Test_EvaluateCandidateUndesiredNegativeReject"), &total, &failed, &failures)
    RunTest("CompareCandidates desired priority", Func("Test_CompareCandidatesDesiredPriority"), &total, &failed, &failures)
    RunTest("CompareCandidates rejected fallback prefers more mandatory", Func("Test_CompareCandidatesRejectedFallback"), &total, &failed, &failures)
    RunTest("EvaluateCandidate invalid counts reject", Func("Test_EvaluateCandidateInvalidCount"), &total, &failed, &failures)
    RunTest("ValidateRuleSlot allows empty undesired", Func("Test_ValidateRuleSlotAllowsEmptyUndesired"), &total, &failed, &failures)
    RunTest("NormalizeRuleSlot clears undesired attributes", Func("Test_NormalizeRuleSlotClearsUndesiredAttributes"), &total, &failed, &failures)
    RunTest("ValidateConfigBundle rejects undesired required positive slot", Func("Test_ValidateConfigBundleRejectsUndesiredRequiredPositive"), &total, &failed, &failures)
    RunTest("TryParseMaxCyclesValue valid", Func("Test_TryParseMaxCyclesValueValid"), &total, &failed, &failures)
    RunTest("TryParseMaxCyclesValue invalid zero", Func("Test_TryParseMaxCyclesValueInvalidZero"), &total, &failed, &failures)
    RunTest("ValidateRuleSlot rejects unknown attr id", Func("Test_ValidateRuleSlotRejectsUnknownAttrId"), &total, &failed, &failures)
    RunTest("State text classification", Func("Test_StateClassification"), &total, &failed, &failures)
    RunTest("Randomized delay stays within jitter range", Func("Test_GetRandomizedDelayRange"), &total, &failed, &failures)
    RunTest("Randomized delay honors minimum", Func("Test_GetRandomizedDelayMinimum"), &total, &failed, &failures)
    RunTest("Randomized click offset stays within range", Func("Test_ApplyRandomClickOffsetRange"), &total, &failed, &failures)
    RunTest("Human mouse path ends at target", Func("Test_BuildHumanMousePathEndsAtTarget"), &total, &failed, &failures)
    RunTest("Human mouse path uses multiple steps for long travel", Func("Test_BuildHumanMousePathUsesMultipleSteps"), &total, &failed, &failures)
    RunTest("Human mouse path handles stationary cursor", Func("Test_BuildHumanMousePathStationary"), &total, &failed, &failures)
    RunTest("Human mouse overshoot extends beyond target when forced", Func("Test_BuildMouseOvershootPointExtendsBeyondTarget"), &total, &failed, &failures)
    RunTest("Human mouse path overshoot settles back on target", Func("Test_BuildHumanMousePathOvershootSettlesOnTarget"), &total, &failed, &failures)
    RunTest("Human mouse overshoot click stays disabled by default", Func("Test_BuildHumanMousePathOvershootClickDisabledByDefault"), &total, &failed, &failures)
    RunTest("Human mouse overshoot click marker forced", Func("Test_BuildHumanMousePathOvershootClickForced"), &total, &failed, &failures)
    RunTest("Idle mouse wander target clamps to bounds", Func("Test_BuildIdleMouseWanderTargetClampsToBounds"), &total, &failed, &failures)
    RunTest("Idle mouse wander distance can force near range", Func("Test_GetIdleMouseWanderDistanceNearRange"), &total, &failed, &failures)
    RunTest("Idle mouse speed can force fast range", Func("Test_GetIdleMouseSpeedMultiplierFastRange"), &total, &failed, &failures)
    RunTest("Safe keystrokes list is copied", Func("Test_GetSafeKeystrokesReturnsCopy"), &total, &failed, &failures)
    RunTest("Random safe keystroke empty list returns blank", Func("Test_GetRandomSafeKeystrokeEmpty"), &total, &failed, &failures)
    RunTest("Random safe keystroke single entry returns that key", Func("Test_GetRandomSafeKeystrokeSingleEntry"), &total, &failed, &failures)
    RunTest("Safe key send token maps named key", Func("Test_BuildSafeKeySendTokenNamedKey"), &total, &failed, &failures)
    RunTest("Safe key send token maps digit", Func("Test_BuildSafeKeySendTokenDigit"), &total, &failed, &failures)
    RunTest("Safe keystroke hold duration forced range", Func("Test_GetRandomSafeKeystrokeHoldDurationForcedRange"), &total, &failed, &failures)
    RunTest("Human long wait disabled returns zero", Func("Test_GetHumanLongWaitDurationDisabled"), &total, &failed, &failures)
    RunTest("Human long wait pre-cycle forced range", Func("Test_GetHumanLongWaitDurationPreCycleForced"), &total, &failed, &failures)
    RunTest("Human long wait unknown phase returns zero", Func("Test_GetHumanLongWaitDurationUnknownPhase"), &total, &failed, &failures)

    passed := total - failed
    summary := "Tests run: " . total . "`nPassed: " . passed . "`nFailed: " . failed
    if (failed > 0) {
        summary .= "`n`nFailures:`n" . JoinArray(failures, "`n")
    }

    LogEvent("INFO", "UnitTestsCompleted", {total: total, passed: passed, failed: failed})
    MsgBox(summary, "Riven Reroller Tests")
}

RunTest(name, testFunc, &total, &failed, &failures) {
    total++
    try {
        testFunc.Call()
    } catch as err {
        failed++
        failures.Push(name . ": " . err.Message)
    }
}

AssertTrue(condition, message := "Assertion failed.") {
    if (!condition) {
        throw Error(message)
    }
}

AssertEqual(expected, actual, message := "") {
    if (expected = actual) {
        return
    }

    detail := message
    if (detail = "") {
        detail := "Expected '" . expected . "' but got '" . actual . "'."
    }
    throw Error(detail)
}

Test_ParseAttributeLineExact() {
    parsed := ParseAttributeLine("+123.4 Critical Chance")
    AssertTrue(IsObject(parsed), "ParseAttributeLine returned false.")
    AssertEqual("critical-chance", parsed.attrId, "Exact label did not map to canonical id.")
    AssertEqual("positive", parsed.polarity)
}

Test_ParseAttributeLineShorthand() {
    parsed := ParseAttributeLine("+90 Crit Chance")
    AssertTrue(IsObject(parsed), "ParseAttributeLine returned false for shorthand.")
    AssertEqual("critical-chance", parsed.attrId, "Shorthand OCR form did not map to canonical id.")
}

Test_ParseAttributeLineIconNoise() {
    parsed := ParseAttributeLine("+59.4 f Electricity")
    AssertTrue(IsObject(parsed), "ParseAttributeLine returned false for icon-noise input.")
    AssertEqual("electricity", parsed.attrId, "Damage type with icon noise did not map to canonical id.")
}

Test_ParseAttributeLinePercentDisplay() {
    parsed := ParseAttributeLine("+132 Toxin")
    AssertTrue(IsObject(parsed), "ParseAttributeLine returned false for toxin.")
    AssertEqual("toxin", parsed.attrId)
    summary := BuildParsedReadSummary({attributes: [parsed]})
    AssertEqual("+132% Toxin", summary, "Expected percent display for toxin.")
}

Test_ParseAttributeLineMultiplierPolarity() {
    parsed := ParseAttributeLine("x0.71 Damage to Corpu")
    AssertTrue(IsObject(parsed), "ParseAttributeLine returned false for multiplier.")
    AssertEqual("damage-to-corpus", parsed.attrId, "Truncated faction should map to damage-to-corpus.")
    AssertEqual("negative", parsed.polarity, "x<1 multiplier should be negative polarity.")
}

Test_ParseAttributeLineSpacedMultiplierDecimal() {
    parsed := ParseAttributeLine("x1 .79 Damage to Infested")
    AssertTrue(IsObject(parsed), "ParseAttributeLine returned false for spaced multiplier decimal.")
    AssertEqual(1.79, parsed.value)
    AssertEqual("positive", parsed.polarity)
}

Test_EvaluateCandidateMandatoryDesired() {
    rules := {
        positiveSlots: [
            {mode: "mandatory", attrIds: ["critical-chance"]},
            {mode: "mandatory", attrIds: ["critical-damage"]},
            {mode: "desired", attrIds: ["multishot"]}
        ],
        negativeSlot: {mode: "desired", attrIds: ["zoom"]}
    }

    candidate := {
        attributes: [
            {attrId: "critical-chance", polarity: "positive"},
            {attrId: "critical-damage", polarity: "positive"},
            {attrId: "multishot", polarity: "positive"},
            {attrId: "zoom", polarity: "negative"}
        ]
    }

    result := EvaluateCandidate(rules, candidate)
    AssertEqual("KEEP", result.status)
    AssertEqual(2, result.mandatoryMatches)
    AssertEqual(2, result.desiredMatches)
}

Test_EvaluateCandidateDesiredNegativeAllowList() {
    rules := {
        positiveSlots: [
            {mode: "mandatory", attrIds: ["critical-chance"]},
            {mode: "mandatory", attrIds: ["cold"]},
            {mode: "desired", attrIds: ["multishot"]}
        ],
        negativeSlot: {mode: "desired", attrIds: ["zoom", "weapon-recoil"]}
    }

    candidate := {
        attributes: [
            {attrId: "critical-chance", polarity: "positive"},
            {attrId: "cold", polarity: "positive"},
            {attrId: "puncture", polarity: "negative"}
        ]
    }

    result := EvaluateCandidate(rules, candidate)
    AssertEqual("REJECT", result.status)
    AssertEqual(2, result.mandatoryMatches)
}

Test_EvaluateCandidateUndesiredPositiveReject() {
    rules := {
        positiveSlots: [
            {mode: "mandatory", attrIds: ["critical-chance"]},
            {mode: "mandatory", attrIds: ["critical-damage"]},
            {mode: "undesired", attrIds: []}
        ],
        negativeSlot: {mode: "indifferent", attrIds: []}
    }

    candidate := {
        attributes: [
            {attrId: "critical-chance", polarity: "positive"},
            {attrId: "critical-damage", polarity: "positive"},
            {attrId: "multishot", polarity: "positive"}
        ]
    }

    result := EvaluateCandidate(rules, candidate)
    AssertEqual("REJECT", result.status)
    AssertEqual(2, result.mandatoryMatches)
}

Test_EvaluateCandidateUndesiredPositiveKeep() {
    rules := {
        positiveSlots: [
            {mode: "mandatory", attrIds: ["critical-chance"]},
            {mode: "mandatory", attrIds: ["critical-damage"]},
            {mode: "undesired", attrIds: []}
        ],
        negativeSlot: {mode: "indifferent", attrIds: []}
    }

    candidate := {
        attributes: [
            {attrId: "critical-chance", polarity: "positive"},
            {attrId: "critical-damage", polarity: "positive"}
        ]
    }

    result := EvaluateCandidate(rules, candidate)
    AssertEqual("KEEP", result.status)
    AssertEqual(2, result.mandatoryMatches)
}

Test_EvaluateCandidateUndesiredNegativeReject() {
    rules := {
        positiveSlots: [
            {mode: "mandatory", attrIds: ["critical-chance"]},
            {mode: "mandatory", attrIds: ["critical-damage"]},
            {mode: "indifferent", attrIds: []}
        ],
        negativeSlot: {mode: "undesired", attrIds: []}
    }

    candidate := {
        attributes: [
            {attrId: "critical-chance", polarity: "positive"},
            {attrId: "critical-damage", polarity: "positive"},
            {attrId: "zoom", polarity: "negative"}
        ]
    }

    result := EvaluateCandidate(rules, candidate)
    AssertEqual("REJECT", result.status)
    AssertEqual(2, result.mandatoryMatches)
}

Test_CompareCandidatesDesiredPriority() {
    rules := {
        positiveSlots: [
            {mode: "mandatory", attrIds: ["critical-chance"]},
            {mode: "mandatory", attrIds: ["critical-damage"]},
            {mode: "desired", attrIds: ["multishot"]}
        ],
        negativeSlot: {mode: "indifferent", attrIds: []}
    }

    currentCandidate := {
        attributes: [
            {attrId: "critical-chance", polarity: "positive"},
            {attrId: "critical-damage", polarity: "positive"},
            {attrId: "damage", polarity: "positive"}
        ]
    }
    incomingCandidate := {
        attributes: [
            {attrId: "critical-chance", polarity: "positive"},
            {attrId: "critical-damage", polarity: "positive"},
            {attrId: "multishot", polarity: "positive"}
        ]
    }

    winner := CompareCandidates(rules, currentCandidate, incomingCandidate)
    AssertEqual("incoming", winner)
}

Test_CompareCandidatesRejectedFallback() {
    rules := {
        positiveSlots: [
            {mode: "mandatory", attrIds: ["critical-chance"]},
            {mode: "mandatory", attrIds: ["critical-damage"]},
            {mode: "indifferent", attrIds: []}
        ],
        negativeSlot: {mode: "indifferent", attrIds: []}
    }

    currentCandidate := {
        attributes: [
            {attrId: "damage", polarity: "positive"},
            {attrId: "multishot", polarity: "positive"}
        ]
    }
    incomingCandidate := {
        attributes: [
            {attrId: "critical-chance", polarity: "positive"},
            {attrId: "damage", polarity: "positive"}
        ]
    }

    winner := CompareCandidates(rules, currentCandidate, incomingCandidate)
    AssertEqual("incoming", winner)
}

Test_EvaluateCandidateInvalidCount() {
    rules := {
        positiveSlots: [
            {mode: "mandatory", attrIds: ["critical-chance"]},
            {mode: "mandatory", attrIds: ["critical-damage"]},
            {mode: "desired", attrIds: ["multishot"]}
        ],
        negativeSlot: {mode: "indifferent", attrIds: []}
    }

    candidate := {attributes: [{attrId: "critical-chance", polarity: "positive"}]}
    result := EvaluateCandidate(rules, candidate)
    AssertEqual("REJECT", result.status)
}

Test_ValidateRuleSlotAllowsEmptyUndesired() {
    validation := ValidateRuleSlot({mode: "undesired", attrIds: []}, "slot")
    AssertTrue(validation.ok, "ValidateRuleSlot should allow empty attrIds for undesired mode.")
}

Test_NormalizeRuleSlotClearsUndesiredAttributes() {
    normalized := NormalizeRuleSlot({mode: "undesired", attrIds: ["zoom"]})
    AssertEqual(0, normalized.attrIds.Length, "NormalizeRuleSlot should clear undesired attrIds.")
}

Test_ValidateConfigBundleRejectsUndesiredRequiredPositive() {
    bundle := BuildValidConfigBundle()
    bundle.profile.rules.positiveSlots[1] := {mode: "undesired", attrIds: []}

    validation := ValidateConfigBundle(bundle)
    AssertTrue(!validation.ok, "ValidateConfigBundle should reject undesired mode on Positive Slot 1.")
}

Test_TryParseMaxCyclesValueValid() {
    ok := TryParseMaxCyclesValue("250", &parsedValue, &errorMessage)
    AssertTrue(ok, "TryParseMaxCyclesValue should accept a valid positive integer.")
    AssertEqual(250, parsedValue)
    AssertEqual("", errorMessage)
}

Test_TryParseMaxCyclesValueInvalidZero() {
    ok := TryParseMaxCyclesValue("0", &parsedValue, &errorMessage)
    AssertTrue(!ok, "TryParseMaxCyclesValue should reject zero.")
    AssertTrue(InStr(errorMessage, "between 1 and 999999") > 0, "Expected range error for zero.")
}

Test_ValidateRuleSlotRejectsUnknownAttrId() {
    validation := ValidateRuleSlot({mode: "mandatory", attrIds: ["not-a-real-attr-id"]}, "slot")
    AssertTrue(!validation.ok, "ValidateRuleSlot should reject unknown attribute ids.")
}

BuildValidConfigBundle() {
    return {
        schemaVersion: "1.0.0",
        appVersion: "1.0.0",
        weaponsCatalogVersion: "1.0.0",
        weaponId: "test-weapon",
        weaponName: "Test Weapon",
        profile: {
            id: "test-profile",
            name: "Test Profile",
            createdAt: "2026-03-17T00:00:00Z",
            updatedAt: "2026-03-17T00:00:00Z",
            rules: {
                positiveSlots: [
                    {mode: "mandatory", attrIds: ["critical-chance"]},
                    {mode: "desired", attrIds: ["critical-damage"]},
                    {mode: "indifferent", attrIds: []}
                ],
                negativeSlot: {mode: "indifferent", attrIds: []}
            }
        }
    }
}

Test_StateClassification() {
    main := ClassifyMainStateText("CYCLE FOR 3500 KUVA")
    AssertEqual("Cycle", main.state)

    confirmCycle := ClassifyConfirmCycleText("Are you sure you want to cycle this Riven Mod?")
    AssertEqual("Confirm Cycle", confirmCycle.state)

    confirmSelection := ClassifyConfirmSelectionText("Cycle your current Riven into your current selection?")
    AssertEqual("Confirm Selection", confirmSelection.state)
}

Test_GetRandomizedDelayRange() {
    global TIMER_JITTER_PERCENT

    originalPercent := TIMER_JITTER_PERCENT
    try {
        TIMER_JITTER_PERCENT := 0.10

        loop 200 {
            randomized := GetRandomizedDelay(1000)
            AssertTrue(randomized >= 900 && randomized <= 1100, "Randomized delay fell outside the expected 10% range.")
        }
    } finally {
        TIMER_JITTER_PERCENT := originalPercent
    }
}

Test_GetRandomizedDelayMinimum() {
    global TIMER_JITTER_PERCENT

    originalPercent := TIMER_JITTER_PERCENT
    try {
        TIMER_JITTER_PERCENT := 0.10

        loop 50 {
            randomized := GetRandomizedDelay(5, 7)
            AssertTrue(randomized >= 7, "Randomized delay should not be lower than the supplied minimum.")
        }
    } finally {
        TIMER_JITTER_PERCENT := originalPercent
    }
}

Test_ApplyRandomClickOffsetRange() {
    global CLICK_POSITION_JITTER_PX

    originalOffset := CLICK_POSITION_JITTER_PX
    try {
        CLICK_POSITION_JITTER_PX := 5

        loop 200 {
            randomized := ApplyRandomClickOffset({x: 100, y: 200})
            AssertTrue(randomized.x >= 95 && randomized.x <= 105, "Randomized click X fell outside the expected range.")
            AssertTrue(randomized.y >= 195 && randomized.y <= 205, "Randomized click Y fell outside the expected range.")
        }
    } finally {
        CLICK_POSITION_JITTER_PX := originalOffset
    }
}

Test_BuildHumanMousePathEndsAtTarget() {
    loop 50 {
        path := BuildHumanMousePath({x: 100, y: 200}, {x: 640, y: 380})
        AssertTrue(path.points.Length > 0, "Expected at least one movement point.")
        lastPoint := path.points[path.points.Length]
        AssertEqual(640, lastPoint.x, "Human mouse path should end on the target X.")
        AssertEqual(380, lastPoint.y, "Human mouse path should end on the target Y.")
        AssertTrue(path.durationMs > 0, "Expected a positive movement duration for non-zero travel.")
    }
}

Test_BuildHumanMousePathUsesMultipleSteps() {
    loop 30 {
        path := BuildHumanMousePath({x: 50, y: 50}, {x: 950, y: 650})
        AssertTrue(path.points.Length >= 2, "Long mouse movement should use multiple points.")
        firstPoint := path.points[1]
        AssertTrue(firstPoint.x != 950 || firstPoint.y != 650, "Long mouse movement should not jump directly to the final point.")
    }
}

Test_BuildHumanMousePathStationary() {
    path := BuildHumanMousePath({x: 300, y: 400}, {x: 300, y: 400})
    AssertEqual(0, path.steps, "Stationary cursor should not create movement steps.")
    AssertEqual(0, path.durationMs, "Stationary cursor should not add movement duration.")
    AssertEqual(0, path.points.Length, "Stationary cursor should not generate path points.")
}

Test_BuildMouseOvershootPointExtendsBeyondTarget() {
    global HUMAN_MOUSE_OVERSHOOT_CHANCE, HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE
    global HUMAN_MOUSE_OVERSHOOT_MIN_PX, HUMAN_MOUSE_OVERSHOOT_MAX_PX, HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX

    originalChance := HUMAN_MOUSE_OVERSHOOT_CHANCE
    originalMinDistance := HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE
    originalMinPx := HUMAN_MOUSE_OVERSHOOT_MIN_PX
    originalMaxPx := HUMAN_MOUSE_OVERSHOOT_MAX_PX
    originalLateral := HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX

    try {
        HUMAN_MOUSE_OVERSHOOT_CHANCE := 1.0
        HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE := 0
        HUMAN_MOUSE_OVERSHOOT_MIN_PX := 10
        HUMAN_MOUSE_OVERSHOOT_MAX_PX := 10
        HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX := 0

        overshootPoint := BuildMouseOvershootPoint({x: 100, y: 100}, {x: 200, y: 100}, 100, 0, 100)
        AssertTrue(IsObject(overshootPoint), "Expected overshoot point when overshoot is forced.")
        AssertEqual(210, overshootPoint.x, "Overshoot point should extend beyond target along travel direction.")
        AssertEqual(100, overshootPoint.y, "Overshoot point should stay on axis without lateral jitter.")
    } finally {
        HUMAN_MOUSE_OVERSHOOT_CHANCE := originalChance
        HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE := originalMinDistance
        HUMAN_MOUSE_OVERSHOOT_MIN_PX := originalMinPx
        HUMAN_MOUSE_OVERSHOOT_MAX_PX := originalMaxPx
        HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX := originalLateral
    }
}

Test_BuildHumanMousePathOvershootSettlesOnTarget() {
    global HUMAN_MOUSE_OVERSHOOT_CHANCE, HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE
    global HUMAN_MOUSE_OVERSHOOT_MIN_PX, HUMAN_MOUSE_OVERSHOOT_MAX_PX, HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX

    originalChance := HUMAN_MOUSE_OVERSHOOT_CHANCE
    originalMinDistance := HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE
    originalMinPx := HUMAN_MOUSE_OVERSHOOT_MIN_PX
    originalMaxPx := HUMAN_MOUSE_OVERSHOOT_MAX_PX
    originalLateral := HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX

    try {
        HUMAN_MOUSE_OVERSHOOT_CHANCE := 1.0
        HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE := 0
        HUMAN_MOUSE_OVERSHOOT_MIN_PX := 12
        HUMAN_MOUSE_OVERSHOOT_MAX_PX := 12
        HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX := 0

        path := BuildHumanMousePath({x: 50, y: 50}, {x: 250, y: 50})
        AssertTrue(path.overshootApplied, "Expected overshoot to be marked as applied when forced.")
        AssertTrue(path.points.Length >= 3, "Overshoot path should include outbound and correction points.")

        sawOvershoot := false
        for point in path.points {
            if (point.x > 250) {
                sawOvershoot := true
                break
            }
        }

        AssertTrue(sawOvershoot, "Expected at least one point beyond the target during overshoot.")
        lastPoint := path.points[path.points.Length]
        AssertEqual(250, lastPoint.x, "Overshoot path should settle back onto target X.")
        AssertEqual(50, lastPoint.y, "Overshoot path should settle back onto target Y.")
    } finally {
        HUMAN_MOUSE_OVERSHOOT_CHANCE := originalChance
        HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE := originalMinDistance
        HUMAN_MOUSE_OVERSHOOT_MIN_PX := originalMinPx
        HUMAN_MOUSE_OVERSHOOT_MAX_PX := originalMaxPx
        HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX := originalLateral
    }
}

Test_BuildHumanMousePathOvershootClickDisabledByDefault() {
    global HUMAN_MOUSE_OVERSHOOT_CHANCE, HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE
    global HUMAN_MOUSE_OVERSHOOT_MIN_PX, HUMAN_MOUSE_OVERSHOOT_MAX_PX, HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX
    global HUMAN_MOUSE_OVERSHOOT_CLICK_CHANCE

    originalChance := HUMAN_MOUSE_OVERSHOOT_CHANCE
    originalMinDistance := HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE
    originalMinPx := HUMAN_MOUSE_OVERSHOOT_MIN_PX
    originalMaxPx := HUMAN_MOUSE_OVERSHOOT_MAX_PX
    originalLateral := HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX
    originalClickChance := HUMAN_MOUSE_OVERSHOOT_CLICK_CHANCE

    try {
        HUMAN_MOUSE_OVERSHOOT_CHANCE := 1.0
        HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE := 0
        HUMAN_MOUSE_OVERSHOOT_MIN_PX := 12
        HUMAN_MOUSE_OVERSHOOT_MAX_PX := 12
        HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX := 0
        HUMAN_MOUSE_OVERSHOOT_CLICK_CHANCE := 1.0

        path := BuildHumanMousePath({x: 50, y: 50}, {x: 250, y: 50})
        AssertTrue(path.overshootApplied, "Expected overshoot to be applied when forced.")
        AssertTrue(!path.overshootClickApplied, "Overshoot click should remain disabled unless explicitly enabled by caller.")
    } finally {
        HUMAN_MOUSE_OVERSHOOT_CHANCE := originalChance
        HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE := originalMinDistance
        HUMAN_MOUSE_OVERSHOOT_MIN_PX := originalMinPx
        HUMAN_MOUSE_OVERSHOOT_MAX_PX := originalMaxPx
        HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX := originalLateral
        HUMAN_MOUSE_OVERSHOOT_CLICK_CHANCE := originalClickChance
    }
}

Test_BuildHumanMousePathOvershootClickForced() {
    global HUMAN_MOUSE_OVERSHOOT_CHANCE, HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE
    global HUMAN_MOUSE_OVERSHOOT_MIN_PX, HUMAN_MOUSE_OVERSHOOT_MAX_PX, HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX
    global HUMAN_MOUSE_OVERSHOOT_CLICK_CHANCE, HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MIN_MS, HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MAX_MS

    originalChance := HUMAN_MOUSE_OVERSHOOT_CHANCE
    originalMinDistance := HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE
    originalMinPx := HUMAN_MOUSE_OVERSHOOT_MIN_PX
    originalMaxPx := HUMAN_MOUSE_OVERSHOOT_MAX_PX
    originalLateral := HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX
    originalClickChance := HUMAN_MOUSE_OVERSHOOT_CLICK_CHANCE
    originalClickPauseMin := HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MIN_MS
    originalClickPauseMax := HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MAX_MS

    try {
        HUMAN_MOUSE_OVERSHOOT_CHANCE := 1.0
        HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE := 0
        HUMAN_MOUSE_OVERSHOOT_MIN_PX := 12
        HUMAN_MOUSE_OVERSHOOT_MAX_PX := 12
        HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX := 0
        HUMAN_MOUSE_OVERSHOOT_CLICK_CHANCE := 1.0
        HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MIN_MS := 55
        HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MAX_MS := 55

        path := BuildHumanMousePath({x: 50, y: 50}, {x: 250, y: 50}, "", true)
        AssertTrue(path.overshootApplied, "Expected overshoot to be applied when forced.")
        AssertTrue(path.overshootClickApplied, "Expected overshoot click to be marked as applied when forced.")

        clickPointIndex := 0
        Loop path.points.Length {
            if (path.points[A_Index].clickAfter) {
                clickPointIndex := A_Index
                break
            }
        }

        AssertTrue(clickPointIndex > 0, "Expected at least one overshoot point to be marked for click.")
        AssertTrue(clickPointIndex < path.points.Length, "Overshoot click should happen before the final settled target point.")
        AssertEqual(55, path.points[clickPointIndex].postClickPauseMs, "Expected overshoot click pause to match forced pause duration.")
    } finally {
        HUMAN_MOUSE_OVERSHOOT_CHANCE := originalChance
        HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE := originalMinDistance
        HUMAN_MOUSE_OVERSHOOT_MIN_PX := originalMinPx
        HUMAN_MOUSE_OVERSHOOT_MAX_PX := originalMaxPx
        HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX := originalLateral
        HUMAN_MOUSE_OVERSHOOT_CLICK_CHANCE := originalClickChance
        HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MIN_MS := originalClickPauseMin
        HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MAX_MS := originalClickPauseMax
    }
}

Test_BuildIdleMouseWanderTargetClampsToBounds() {
    bounds := {minX: 2, minY: 2, maxX: 100, maxY: 100}
    clampedRight := BuildIdleMouseWanderTargetFromOrigin({x: 95, y: 50}, bounds, 30, 0.0)
    AssertEqual(100, clampedRight.x, "Idle wander target should clamp to right bound.")
    AssertEqual(50, clampedRight.y, "Idle wander target should preserve Y when no vertical change exists.")

    clampedTop := BuildIdleMouseWanderTargetFromOrigin({x: 50, y: 5}, bounds, 20, 4.71238898038469)
    AssertEqual(50, clampedTop.x, "Idle wander target should preserve X when no horizontal change exists.")
    AssertEqual(2, clampedTop.y, "Idle wander target should clamp to top bound.")
}

Test_GetIdleMouseWanderDistanceNearRange() {
    global HUMAN_MOUSE_IDLE_NEAR_MOVE_CHANCE
    global HUMAN_MOUSE_IDLE_NEAR_MIN_PX, HUMAN_MOUSE_IDLE_NEAR_MAX_PX

    originalChance := HUMAN_MOUSE_IDLE_NEAR_MOVE_CHANCE
    originalMin := HUMAN_MOUSE_IDLE_NEAR_MIN_PX
    originalMax := HUMAN_MOUSE_IDLE_NEAR_MAX_PX

    try {
        HUMAN_MOUSE_IDLE_NEAR_MOVE_CHANCE := 1.0
        HUMAN_MOUSE_IDLE_NEAR_MIN_PX := 11
        HUMAN_MOUSE_IDLE_NEAR_MAX_PX := 11
        distancePx := GetIdleMouseWanderDistance()
        AssertEqual(11, distancePx, "Expected near idle wander distance when near range is forced.")
    } finally {
        HUMAN_MOUSE_IDLE_NEAR_MOVE_CHANCE := originalChance
        HUMAN_MOUSE_IDLE_NEAR_MIN_PX := originalMin
        HUMAN_MOUSE_IDLE_NEAR_MAX_PX := originalMax
    }
}

Test_GetIdleMouseSpeedMultiplierFastRange() {
    global HUMAN_MOUSE_IDLE_FAST_MOVE_CHANCE
    global HUMAN_MOUSE_IDLE_FAST_SPEED_MIN, HUMAN_MOUSE_IDLE_FAST_SPEED_MAX

    originalChance := HUMAN_MOUSE_IDLE_FAST_MOVE_CHANCE
    originalMin := HUMAN_MOUSE_IDLE_FAST_SPEED_MIN
    originalMax := HUMAN_MOUSE_IDLE_FAST_SPEED_MAX

    try {
        HUMAN_MOUSE_IDLE_FAST_MOVE_CHANCE := 1.0
        HUMAN_MOUSE_IDLE_FAST_SPEED_MIN := 0.75
        HUMAN_MOUSE_IDLE_FAST_SPEED_MAX := 0.75
        speedMultiplier := GetIdleMouseSpeedMultiplier()
        AssertEqual(0.75, speedMultiplier, "Expected fast idle speed multiplier when fast range is forced.")
    } finally {
        HUMAN_MOUSE_IDLE_FAST_MOVE_CHANCE := originalChance
        HUMAN_MOUSE_IDLE_FAST_SPEED_MIN := originalMin
        HUMAN_MOUSE_IDLE_FAST_SPEED_MAX := originalMax
    }
}

Test_GetSafeKeystrokesReturnsCopy() {
    global SAFE_KEYSTROKES

    originalKeys := SAFE_KEYSTROKES
    try {
        SAFE_KEYSTROKES := ["{Shift}", "r"]
        copiedKeys := GetSafeKeystrokes()
        AssertEqual(2, copiedKeys.Length, "Expected copied safe keystroke count to match source.")
        copiedKeys.Push("x")
        AssertEqual(2, SAFE_KEYSTROKES.Length, "Mutating copied keystrokes should not affect config list.")
    } finally {
        SAFE_KEYSTROKES := originalKeys
    }
}

Test_GetRandomSafeKeystrokeEmpty() {
    global SAFE_KEYSTROKES

    originalKeys := SAFE_KEYSTROKES
    try {
        SAFE_KEYSTROKES := []
        AssertEqual("", GetRandomSafeKeystroke(), "Expected blank safe keystroke when list is empty.")
    } finally {
        SAFE_KEYSTROKES := originalKeys
    }
}

Test_GetRandomSafeKeystrokeSingleEntry() {
    global SAFE_KEYSTROKES

    originalKeys := SAFE_KEYSTROKES
    try {
        SAFE_KEYSTROKES := ["{Left}"]
        AssertEqual("{Left}", GetRandomSafeKeystroke(), "Expected the only configured safe keystroke to be returned.")
    } finally {
        SAFE_KEYSTROKES := originalKeys
    }
}

Test_BuildSafeKeySendTokenNamedKey() {
    AssertEqual("Left", BuildSafeKeySendToken("{Left}"), "Expected named safe key to unwrap to AHK send token.")
}

Test_BuildSafeKeySendTokenDigit() {
    AssertEqual("vk37", BuildSafeKeySendToken("7"), "Expected digit safe key to map to virtual-key token.")
}

Test_GetRandomSafeKeystrokeHoldDurationForcedRange() {
    global SAFE_KEYSTROKE_HOLD_MIN_MS, SAFE_KEYSTROKE_HOLD_MAX_MS

    originalMin := SAFE_KEYSTROKE_HOLD_MIN_MS
    originalMax := SAFE_KEYSTROKE_HOLD_MAX_MS
    try {
        SAFE_KEYSTROKE_HOLD_MIN_MS := 64
        SAFE_KEYSTROKE_HOLD_MAX_MS := 64
        AssertEqual(64, GetRandomSafeKeystrokeHoldDuration(), "Expected hold duration to match forced min/max range.")
    } finally {
        SAFE_KEYSTROKE_HOLD_MIN_MS := originalMin
        SAFE_KEYSTROKE_HOLD_MAX_MS := originalMax
    }
}

Test_GetHumanLongWaitDurationDisabled() {
    global HUMAN_LONG_WAIT_ENABLED

    originalEnabled := HUMAN_LONG_WAIT_ENABLED
    try {
        HUMAN_LONG_WAIT_ENABLED := false
        AssertEqual(0, GetHumanLongWaitDuration("preCycleStart"), "Disabled long waits should always return zero.")
    } finally {
        HUMAN_LONG_WAIT_ENABLED := originalEnabled
    }
}

Test_GetHumanLongWaitDurationPreCycleForced() {
    global HUMAN_LONG_WAIT_ENABLED
    global HUMAN_LONG_WAIT_PRE_CYCLE_CHANCE, HUMAN_LONG_WAIT_PRE_CYCLE_MIN_MS, HUMAN_LONG_WAIT_PRE_CYCLE_MAX_MS

    originalEnabled := HUMAN_LONG_WAIT_ENABLED
    originalChance := HUMAN_LONG_WAIT_PRE_CYCLE_CHANCE
    originalMin := HUMAN_LONG_WAIT_PRE_CYCLE_MIN_MS
    originalMax := HUMAN_LONG_WAIT_PRE_CYCLE_MAX_MS

    try {
        HUMAN_LONG_WAIT_ENABLED := true
        HUMAN_LONG_WAIT_PRE_CYCLE_CHANCE := 1.0
        HUMAN_LONG_WAIT_PRE_CYCLE_MIN_MS := 2500
        HUMAN_LONG_WAIT_PRE_CYCLE_MAX_MS := 2500
        AssertEqual(2500, GetHumanLongWaitDuration("preCycleStart"), "Forced pre-cycle long wait should return configured duration.")
    } finally {
        HUMAN_LONG_WAIT_ENABLED := originalEnabled
        HUMAN_LONG_WAIT_PRE_CYCLE_CHANCE := originalChance
        HUMAN_LONG_WAIT_PRE_CYCLE_MIN_MS := originalMin
        HUMAN_LONG_WAIT_PRE_CYCLE_MAX_MS := originalMax
    }
}

Test_GetHumanLongWaitDurationUnknownPhase() {
    AssertEqual(0, GetHumanLongWaitDuration("not-a-real-phase"), "Unknown long wait phase should return zero.")
}
