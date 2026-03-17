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
    RunTest("CompareCandidates desired priority", Func("Test_CompareCandidatesDesiredPriority"), &total, &failed, &failures)
    RunTest("EvaluateCandidate invalid counts reject", Func("Test_EvaluateCandidateInvalidCount"), &total, &failed, &failures)
    RunTest("State text classification", Func("Test_StateClassification"), &total, &failed, &failures)

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

Test_StateClassification() {
    main := ClassifyMainStateText("CYCLE FOR 3500 KUVA")
    AssertEqual("Cycle", main.state)

    confirmCycle := ClassifyConfirmCycleText("Are you sure you want to cycle this Riven Mod?")
    AssertEqual("Confirm Cycle", confirmCycle.state)

    confirmSelection := ClassifyConfirmSelectionText("Cycle your current Riven into your current selection?")
    AssertEqual("Confirm Selection", confirmSelection.state)
}
