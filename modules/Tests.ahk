; ===== UNIT TESTS =====
RunUnitTests() {
    results := CollectUnitTestResults()
    summary := FormatUnitTestSummary(results)

    LogEvent("INFO", "UnitTestsCompleted", {total: results.total, passed: results.passed, failed: results.failed})
    MsgBox(summary, "Riven Reroller Tests")
}

RunUnitTestsHeadless(outputPath := "") {
    results := CollectUnitTestResults()
    summary := FormatUnitTestSummary(results)

    if (outputPath != "") {
        try {
            FileDelete(outputPath)
        }
        try {
            FileAppend(summary, outputPath, "UTF-8")
        }
    }

    LogEvent("INFO", "UnitTestsCompleted", {total: results.total, passed: results.passed, failed: results.failed})
    return results
}

CollectUnitTestResults() {
    total := 0
    failed := 0
    failures := []

    for testSpec in BuildUnitTestSuite() {
        RunTest(testSpec[1], testSpec[2], &total, &failed, &failures)
    }

    return {
        total: total,
        passed: total - failed,
        failed: failed,
        failures: failures
    }
}

BuildUnitTestSuite() {
    tests := []

    tests.Push(["ParseAttributeLine exact mapping", "Test_ParseAttributeLineExact"])
    tests.Push(["ParseAttributeLine OCR shorthand mapping", "Test_ParseAttributeLineShorthand"])
    tests.Push(["ParseAttributeLine icon noise mapping", "Test_ParseAttributeLineIconNoise"])
    tests.Push(["ParseAttributeLine percent display", "Test_ParseAttributeLinePercentDisplay"])
    tests.Push(["ParseAttributeLine multiplier polarity/mapping", "Test_ParseAttributeLineMultiplierPolarity"])
    tests.Push(["ParseAttributeLine spaced multiplier decimal", "Test_ParseAttributeLineSpacedMultiplierDecimal"])
    tests.Push(["EvaluateCandidate mandatory/desired", "Test_EvaluateCandidateMandatoryDesired"])
    tests.Push(["EvaluateCandidate desired negative allow-list", "Test_EvaluateCandidateDesiredNegativeAllowList"])
    tests.Push(["EvaluateCandidate undesired positive rejects third positive", "Test_EvaluateCandidateUndesiredPositiveReject"])
    tests.Push(["EvaluateCandidate undesired positive keeps two positives", "Test_EvaluateCandidateUndesiredPositiveKeep"])
    tests.Push(["EvaluateCandidate undesired negative rejects any negative", "Test_EvaluateCandidateUndesiredNegativeReject"])
    tests.Push(["CompareCandidates desired priority", "Test_CompareCandidatesDesiredPriority"])
    tests.Push(["CompareCandidates rejected fallback prefers more mandatory", "Test_CompareCandidatesRejectedFallback"])
    tests.Push(["Perfect current riven stop reason returned", "Test_GetPerfectCurrentRivenStopReasonPerfect"])
    tests.Push(["EvaluateCandidate invalid counts reject", "Test_EvaluateCandidateInvalidCount"])
    tests.Push(["ValidateRuleSlot allows empty undesired", "Test_ValidateRuleSlotAllowsEmptyUndesired"])
    tests.Push(["NormalizeRuleSlot clears undesired attributes", "Test_NormalizeRuleSlotClearsUndesiredAttributes"])
    tests.Push(["ValidateConfigBundle rejects undesired required positive slot", "Test_ValidateConfigBundleRejectsUndesiredRequiredPositive"])
    tests.Push(["TryParseMaxCyclesValue valid", "Test_TryParseMaxCyclesValueValid"])
    tests.Push(["TryParseMaxCyclesValue invalid zero", "Test_TryParseMaxCyclesValueInvalidZero"])
    tests.Push(["ValidateRuleSlot rejects unknown attr id", "Test_ValidateRuleSlotRejectsUnknownAttrId"])
    tests.Push(["State text classification", "Test_StateClassification"])
    tests.Push(["Randomized delay stays within jitter range", "Test_GetRandomizedDelayRange"])
    tests.Push(["Randomized delay honors minimum", "Test_GetRandomizedDelayMinimum"])
    tests.Push(["Randomized click offset stays within range", "Test_ApplyRandomClickOffsetRange"])
    tests.Push(["Human mouse path ends at target", "Test_BuildHumanMousePathEndsAtTarget"])
    tests.Push(["Human mouse path uses multiple steps for long travel", "Test_BuildHumanMousePathUsesMultipleSteps"])
    tests.Push(["Human mouse path handles stationary cursor", "Test_BuildHumanMousePathStationary"])
    tests.Push(["Human mouse overshoot extends beyond target when forced", "Test_BuildMouseOvershootPointExtendsBeyondTarget"])
    tests.Push(["Human mouse path overshoot settles back on target", "Test_BuildHumanMousePathOvershootSettlesOnTarget"])
    tests.Push(["Human mouse overshoot click stays disabled by default", "Test_BuildHumanMousePathOvershootClickDisabledByDefault"])
    tests.Push(["Human mouse overshoot click marker forced", "Test_BuildHumanMousePathOvershootClickForced"])
    tests.Push(["Idle mouse wander target clamps to bounds", "Test_BuildIdleMouseWanderTargetClampsToBounds"])
    tests.Push(["Idle mouse wander distance can force near range", "Test_GetIdleMouseWanderDistanceNearRange"])
    tests.Push(["Idle mouse speed can force fast range", "Test_GetIdleMouseSpeedMultiplierFastRange"])
    tests.Push(["Default safe keystrokes exclude CapsLock", "Test_DefaultSafeKeystrokesExcludeCapsLock"])
    tests.Push(["Safe keystrokes list is copied", "Test_GetSafeKeystrokesReturnsCopy"])
    tests.Push(["Random safe keystroke empty list returns blank", "Test_GetRandomSafeKeystrokeEmpty"])
    tests.Push(["Random safe keystroke single entry returns that key", "Test_GetRandomSafeKeystrokeSingleEntry"])
    tests.Push(["Safe key send token maps named key", "Test_BuildSafeKeySendTokenNamedKey"])
    tests.Push(["Safe key send token maps digit", "Test_BuildSafeKeySendTokenDigit"])
    tests.Push(["Safe keystroke hold duration forced range", "Test_GetRandomSafeKeystrokeHoldDurationForcedRange"])
    tests.Push(["Human long wait disabled returns zero", "Test_GetHumanLongWaitDurationDisabled"])
    tests.Push(["Human long wait pre-cycle forced range", "Test_GetHumanLongWaitDurationPreCycleForced"])
    tests.Push(["Human long wait unknown phase returns zero", "Test_GetHumanLongWaitDurationUnknownPhase"])

    return tests
}

FormatUnitTestSummary(results) {
    summary := "Tests run: " . results.total . "`nPassed: " . results.passed . "`nFailed: " . results.failed
    if (results.failed > 0) {
        summary .= "`n`nFailures:`n" . JoinArray(results.failures, "`n")
    }
    return summary
}

RunTest(name, testFunc, &total, &failed, &failures) {
    total++
    try {
        CallUnitTestByName(testFunc)
    } catch as err {
        failed++
        failures.Push(name . ": " . err.Message)
    }
}

CallUnitTestByName(testName) {
    switch testName {
        case "Test_ParseAttributeLineExact":
            Test_ParseAttributeLineExact()
        case "Test_ParseAttributeLineShorthand":
            Test_ParseAttributeLineShorthand()
        case "Test_ParseAttributeLineIconNoise":
            Test_ParseAttributeLineIconNoise()
        case "Test_ParseAttributeLinePercentDisplay":
            Test_ParseAttributeLinePercentDisplay()
        case "Test_ParseAttributeLineMultiplierPolarity":
            Test_ParseAttributeLineMultiplierPolarity()
        case "Test_ParseAttributeLineSpacedMultiplierDecimal":
            Test_ParseAttributeLineSpacedMultiplierDecimal()
        case "Test_EvaluateCandidateMandatoryDesired":
            Test_EvaluateCandidateMandatoryDesired()
        case "Test_EvaluateCandidateDesiredNegativeAllowList":
            Test_EvaluateCandidateDesiredNegativeAllowList()
        case "Test_EvaluateCandidateUndesiredPositiveReject":
            Test_EvaluateCandidateUndesiredPositiveReject()
        case "Test_EvaluateCandidateUndesiredPositiveKeep":
            Test_EvaluateCandidateUndesiredPositiveKeep()
        case "Test_EvaluateCandidateUndesiredNegativeReject":
            Test_EvaluateCandidateUndesiredNegativeReject()
        case "Test_CompareCandidatesDesiredPriority":
            Test_CompareCandidatesDesiredPriority()
        case "Test_CompareCandidatesRejectedFallback":
            Test_CompareCandidatesRejectedFallback()
        case "Test_GetPerfectCurrentRivenStopReasonPerfect":
            Test_GetPerfectCurrentRivenStopReasonPerfect()
        case "Test_EvaluateCandidateInvalidCount":
            Test_EvaluateCandidateInvalidCount()
        case "Test_ValidateRuleSlotAllowsEmptyUndesired":
            Test_ValidateRuleSlotAllowsEmptyUndesired()
        case "Test_NormalizeRuleSlotClearsUndesiredAttributes":
            Test_NormalizeRuleSlotClearsUndesiredAttributes()
        case "Test_ValidateConfigBundleRejectsUndesiredRequiredPositive":
            Test_ValidateConfigBundleRejectsUndesiredRequiredPositive()
        case "Test_TryParseMaxCyclesValueValid":
            Test_TryParseMaxCyclesValueValid()
        case "Test_TryParseMaxCyclesValueInvalidZero":
            Test_TryParseMaxCyclesValueInvalidZero()
        case "Test_ValidateRuleSlotRejectsUnknownAttrId":
            Test_ValidateRuleSlotRejectsUnknownAttrId()
        case "Test_StateClassification":
            Test_StateClassification()
        case "Test_GetRandomizedDelayRange":
            Test_GetRandomizedDelayRange()
        case "Test_GetRandomizedDelayMinimum":
            Test_GetRandomizedDelayMinimum()
        case "Test_ApplyRandomClickOffsetRange":
            Test_ApplyRandomClickOffsetRange()
        case "Test_BuildHumanMousePathEndsAtTarget":
            Test_BuildHumanMousePathEndsAtTarget()
        case "Test_BuildHumanMousePathUsesMultipleSteps":
            Test_BuildHumanMousePathUsesMultipleSteps()
        case "Test_BuildHumanMousePathStationary":
            Test_BuildHumanMousePathStationary()
        case "Test_BuildMouseOvershootPointExtendsBeyondTarget":
            Test_BuildMouseOvershootPointExtendsBeyondTarget()
        case "Test_BuildHumanMousePathOvershootSettlesOnTarget":
            Test_BuildHumanMousePathOvershootSettlesOnTarget()
        case "Test_BuildHumanMousePathOvershootClickDisabledByDefault":
            Test_BuildHumanMousePathOvershootClickDisabledByDefault()
        case "Test_BuildHumanMousePathOvershootClickForced":
            Test_BuildHumanMousePathOvershootClickForced()
        case "Test_BuildIdleMouseWanderTargetClampsToBounds":
            Test_BuildIdleMouseWanderTargetClampsToBounds()
        case "Test_GetIdleMouseWanderDistanceNearRange":
            Test_GetIdleMouseWanderDistanceNearRange()
        case "Test_GetIdleMouseSpeedMultiplierFastRange":
            Test_GetIdleMouseSpeedMultiplierFastRange()
        case "Test_DefaultSafeKeystrokesExcludeCapsLock":
            Test_DefaultSafeKeystrokesExcludeCapsLock()
        case "Test_GetSafeKeystrokesReturnsCopy":
            Test_GetSafeKeystrokesReturnsCopy()
        case "Test_GetRandomSafeKeystrokeEmpty":
            Test_GetRandomSafeKeystrokeEmpty()
        case "Test_GetRandomSafeKeystrokeSingleEntry":
            Test_GetRandomSafeKeystrokeSingleEntry()
        case "Test_BuildSafeKeySendTokenNamedKey":
            Test_BuildSafeKeySendTokenNamedKey()
        case "Test_BuildSafeKeySendTokenDigit":
            Test_BuildSafeKeySendTokenDigit()
        case "Test_GetRandomSafeKeystrokeHoldDurationForcedRange":
            Test_GetRandomSafeKeystrokeHoldDurationForcedRange()
        case "Test_GetHumanLongWaitDurationDisabled":
            Test_GetHumanLongWaitDurationDisabled()
        case "Test_GetHumanLongWaitDurationPreCycleForced":
            Test_GetHumanLongWaitDurationPreCycleForced()
        case "Test_GetHumanLongWaitDurationUnknownPhase":
            Test_GetHumanLongWaitDurationUnknownPhase()
        default:
            throw Error("Unknown unit test: " . testName)
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

Test_GetPerfectCurrentRivenStopReasonPerfect() {
    global ACTIVE_RULES

    originalRules := ACTIVE_RULES
    try {
        ACTIVE_RULES := {
            positiveSlots: [
                {mode: "mandatory", attrIds: ["critical-chance"]},
                {mode: "mandatory", attrIds: ["critical-damage"]},
                {mode: "desired", attrIds: ["multishot"]}
            ],
            negativeSlot: {mode: "undesired", attrIds: []}
        }

        rivenData := {
            attributes: [
                {attrId: "critical-chance", polarity: "positive"},
                {attrId: "critical-damage", polarity: "positive"},
                {attrId: "multishot", polarity: "positive"}
            ]
        }

        AssertEqual(
            "Perfect current riven detected before cycling.",
            GetPerfectCurrentRivenStopReason(rivenData),
            "Expected a stop reason when the current riven is already perfect."
        )
    } finally {
        ACTIVE_RULES := originalRules
    }
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

Test_DefaultSafeKeystrokesExcludeCapsLock() {
    keys := GetSafeKeystrokes()
    AssertTrue(!ArrayContains(keys, "{CapsLock}"), "Default safe keystroke list should not include CapsLock.")
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
