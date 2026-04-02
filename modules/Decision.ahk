; ---------------------------------------------------------------------
; ===== DECISION MAKING (CONFIGURATOR RULE MODEL) =====
; ---------------------------------------------------------------------

EvaluateCandidate(rules, candidate) {
    reasons := []
    totals := GetCandidateStats(candidate)

    if (totals.totalCount < 2 || totals.totalCount > 4) {
        reasons.Push("Total attribute count (" . totals.totalCount . ") must be between 2 and 4.")
    }
    if (totals.positiveCount < 2 || totals.positiveCount > 3) {
        reasons.Push("Positive attribute count (" . totals.positiveCount . ") must be 2 or 3.")
    }
    if (totals.negativeCount > 1) { ; error, it is not possible to have more than 1 negative attribute on a Riven
        reasons.Push("Only one negative attribute is allowed.")
    }

    if (reasons.Length > 0) {
        return RejectCandidate(reasons, 0)
    }

    if (rules.positiveSlots[1].mode = "undesired" || rules.positiveSlots[2].mode = "undesired") {
        return RejectCandidate(["Rule configuration is invalid: Positive Slot 1 and Positive Slot 2 cannot use undesired mode."])
    }

    slotsRequiringAttrIds := []
    for slot in rules.positiveSlots {
        if (SlotModeRequiresAttrIds(slot.mode)) {
            slotsRequiringAttrIds.Push(slot)
        }
    }
    if (SlotModeRequiresAttrIds(rules.negativeSlot.mode)) {
        slotsRequiringAttrIds.Push(rules.negativeSlot)
    }
    for slot in slotsRequiringAttrIds {
        if (slot.attrIds.Length = 0) {
            return RejectCandidate(["Rule configuration is invalid: slots in mandatory and desired mode must contain attributes."])
        }
    }

    mandatoryPositiveSlots := []
    for slot in rules.positiveSlots {
        if (slot.mode = "mandatory") {
            mandatoryPositiveSlots.Push(slot)
        }
    }

    mandatoryPositiveMatches := ComputeMaxDistinctSlotMatches(mandatoryPositiveSlots, totals.positiveIds)
    if (mandatoryPositiveMatches < mandatoryPositiveSlots.Length) {
        return RejectCandidate(
            ["Missing mandatory positive slot matches: " . mandatoryPositiveMatches . "/" . mandatoryPositiveSlots.Length . " satisfied."],
            mandatoryPositiveMatches
        )
    }

    mandatoryNegativeMatches := 0
    negativeAttrId := totals.negativeCount > 0 ? totals.negativeIds[1] : ""

    if (rules.negativeSlot.mode = "mandatory") {
        if (negativeAttrId = "") {
            return RejectCandidate(["Missing mandatory negative attribute."], mandatoryPositiveMatches)
        }
        if (!ArrayContains(rules.negativeSlot.attrIds, negativeAttrId)) {
            return RejectCandidate(["Negative attribute does not match the mandatory negative slot."], mandatoryPositiveMatches)
        }
        mandatoryNegativeMatches := 1
    } else if (rules.negativeSlot.mode = "desired") {
        if (negativeAttrId != "" && !ArrayContains(rules.negativeSlot.attrIds, negativeAttrId)) {
            return RejectCandidate(["Negative attribute is not allowed by the configured negative slot."], mandatoryPositiveMatches)
        }
    }

    mandatoryTotalMatches := mandatoryPositiveMatches + mandatoryNegativeMatches

    if (rules.positiveSlots[3].mode = "undesired" && totals.positiveCount > 2) {
        return RejectCandidate(["Positive Slot 3 is undesired, but the Riven has a third positive attribute."], mandatoryTotalMatches)
    }
    if (rules.negativeSlot.mode = "undesired" && negativeAttrId != "") {
        return RejectCandidate(["Negative Slot is undesired, but the Riven has a negative attribute."], mandatoryTotalMatches)
    }

    desiredMatches := 0
    for slot in rules.positiveSlots {
        if (slot.mode = "desired" && SlotHasAnyMatch(slot, totals.positiveSet)) {
            desiredMatches++
        }
    }
    if (rules.negativeSlot.mode = "desired") {
        if (negativeAttrId != "" && ArrayContains(rules.negativeSlot.attrIds, negativeAttrId)) {
            desiredMatches++
        }
    }

    return {
        status: "KEEP",
        hardRejected: false,
        reasons: [],
        mandatoryMatches: mandatoryTotalMatches,
        desiredMatches: desiredMatches
    }
}

RejectCandidate(reasons, mandatoryMatches := 0) {
    return {
        status: "REJECT",
        hardRejected: true,
        reasons: reasons,
        mandatoryMatches: mandatoryMatches,
        desiredMatches: 0
    }
}

GetCandidateStats(candidate) {
    positiveIds := []
    negativeIds := []
    positiveSet := Map()
    negativeSet := Map()

    for attribute in candidate.attributes {
        if (attribute.polarity = "negative") {
            negativeIds.Push(attribute.attrId)
            negativeSet[attribute.attrId] := true
        } else {
            positiveIds.Push(attribute.attrId)
            positiveSet[attribute.attrId] := true
        }
    }

    return {
        totalCount: candidate.attributes.Length,
        positiveCount: positiveIds.Length,
        negativeCount: negativeIds.Length,
        positiveIds: positiveIds,
        negativeIds: negativeIds,
        positiveSet: positiveSet,
        negativeSet: negativeSet
    }
}

SlotHasAnyMatch(slot, candidateSet) {
    for attrId in slot.attrIds {
        if (candidateSet.Has(attrId)) {
            return true
        }
    }
    return false
}

SlotModeRequiresAttrIds(mode) {
    return mode = "mandatory" || mode = "desired"
}

ComputeMaxDistinctSlotMatches(slots, candidateIds) {
    if (slots.Length = 0 || candidateIds.Length = 0) {
        return 0
    }

    slotAllowedSets := []
    for slot in slots {
        allowed := Map()
        for attrId in slot.attrIds {
            allowed[attrId] := true
        }
        slotAllowedSets.Push(allowed)
    }

    candidateToSlot := []
    loop candidateIds.Length {
        candidateToSlot.Push(0)
    }

    matches := 0
    loop slots.Length {
        slotIndex := A_Index
        seen := []
        loop candidateIds.Length {
            seen.Push(false)
        }
        if (TryMatchSlot(slotIndex, seen, slotAllowedSets, candidateIds, candidateToSlot)) {
            matches++
        }
    }

    return matches
}

TryMatchSlot(slotIndex, seen, slotAllowedSets, candidateIds, candidateToSlot) {
    for candidateIndex, candidateId in candidateIds {
        if (seen[candidateIndex]) {
            continue
        }
        if (!slotAllowedSets[slotIndex].Has(candidateId)) {
            continue
        }

        seen[candidateIndex] := true
        currentSlot := candidateToSlot[candidateIndex]
        if (currentSlot = 0 || TryMatchSlot(currentSlot, seen, slotAllowedSets, candidateIds, candidateToSlot)) {
            candidateToSlot[candidateIndex] := slotIndex
            return true
        }
    }

    return false
}

CompareCandidates(rules, currentCandidate, incomingCandidate) {
    currentResult := EvaluateCandidate(rules, currentCandidate)
    incomingResult := EvaluateCandidate(rules, incomingCandidate)

    if (currentResult.status = "REJECT" && incomingResult.status = "KEEP") {
        return "incoming"
    }
    if (currentResult.status = "KEEP" && incomingResult.status = "REJECT") {
        return "current"
    }

    if (ShouldPreferIncomingResult(currentResult, incomingResult)) {
        return "incoming"
    }

    return "current"
}

ShouldPreferIncomingResult(currentResult, incomingResult) {
    if (incomingResult.mandatoryMatches > currentResult.mandatoryMatches) {
        return true
    }
    if (currentResult.mandatoryMatches > incomingResult.mandatoryMatches) {
        return false
    }

    return incomingResult.desiredMatches > currentResult.desiredMatches
}

CompareRivens(oldRiven, newRiven) {
    global ACTIVE_RULES

    currentCandidate := BuildCandidateFromParsedAttributes(oldRiven)
    incomingCandidate := BuildCandidateFromParsedAttributes(newRiven)

    winner := CompareCandidates(ACTIVE_RULES, currentCandidate, incomingCandidate)
    return winner = "incoming" ? "new" : "old"
}

IsPerfectRiven(rivenData) {
    global ACTIVE_RULES

    candidate := BuildCandidateFromParsedAttributes(rivenData)
    totals := GetCandidateStats(candidate)
    result := EvaluateCandidate(ACTIVE_RULES, candidate)
    if (result.status != "KEEP") {
        return false
    }

    ; Desired negative only counts toward "perfect" when a negative attribute is actually present.
    expectedDesired := 0
    for slot in ACTIVE_RULES.positiveSlots {
        if (slot.mode = "desired" && slot.attrIds.Length > 0) {
            expectedDesired++
        }
    }
    if (ACTIVE_RULES.negativeSlot.mode = "desired" && ACTIVE_RULES.negativeSlot.attrIds.Length > 0 && totals.negativeCount > 0) {
        expectedDesired++
    }

    mandatoryTotal := 0
    for slot in ACTIVE_RULES.positiveSlots {
        if (slot.mode = "mandatory") {
            mandatoryTotal++
        }
    }
    if (ACTIVE_RULES.negativeSlot.mode = "mandatory") {
        mandatoryTotal++
    }

    return result.mandatoryMatches >= mandatoryTotal && result.desiredMatches >= expectedDesired
}

GetRivenSummary(rivenData) {
    global ACTIVE_RULES

    if (!rivenData.HasOwnProp("attributes") || rivenData.attributes.Length = 0) {
        return "No attributes found."
    }

    candidate := BuildCandidateFromParsedAttributes(rivenData)
    result := EvaluateCandidate(ACTIVE_RULES, candidate)

    summary := ""
    summary .= "Status: " . result.status . "`n"
    summary .= "Mandatory matches: " . result.mandatoryMatches . "`n"
    summary .= "Desired matches: " . result.desiredMatches . "`n"
    if (result.reasons.Length > 0) {
        summary .= "Reasons: " . JoinArray(result.reasons, " | ") . "`n"
    }
    summary .= "`n"

    for attr in rivenData.attributes {
        label := attr.HasOwnProp("label") ? attr.label : attr.raw
        summary .= attr.symbol . attr.value . " " . label
        if (attr.HasOwnProp("attrId") && attr.attrId != "") {
            summary .= " (" . attr.attrId . ")"
        }
        summary .= "`n"
    }

    return summary
}

ArrayContains(arr, target) {
    for item in arr {
        if (item = target) {
            return true
        }
    }
    return false
}

JoinArray(arr, separator := ", ") {
    out := ""
    for index, value in arr {
        if (index > 1) {
            out .= separator
        }
        out .= value
    }
    return out
}
