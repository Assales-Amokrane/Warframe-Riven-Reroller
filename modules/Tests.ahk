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
