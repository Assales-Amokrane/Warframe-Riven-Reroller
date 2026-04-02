; ===== ACTIONS =====
StartCycle() {
    return SafeClickAction("startCycle")
}

ConfirmCycleStart() {
    return SafeClickAction("confirmCycleStart")
}

PickOldRiven() {
    return SafeClickAction("pickOldRiven")
}

StartSelection() {
    return SafeClickAction("startSelection")
}

ConfirmSelectionAction() {
    return SafeClickAction("confirmSelection")
}

SafeClickAction(actionName) {
    if (!EnsureWarframeWindow()) {
        LogEvent("WARN", "ActionSkippedWindowNotFocused", {action: actionName})
        return false
    }

    baseCoords := GetActionCoord(actionName)
    clickCoords := ApplyRandomClickOffset(baseCoords)
    movementMeta := MoveMouseHumanized(clickCoords, "", true)
    Click clickCoords.x, clickCoords.y
    SleepRandomized(100)

    LogEvent("INFO", "ActionClick", {
        action: actionName,
        x: clickCoords.x,
        y: clickCoords.y,
        baseX: baseCoords.x,
        baseY: baseCoords.y,
        moveSteps: movementMeta.steps,
        moveDurationMs: movementMeta.durationMs
    })
    return true
}

MoveMouseHumanized(targetPoint, speedMultiplier := "", allowOvershootClick := false) {
    global HUMAN_MOUSE_ENABLED

    MouseGetPos &startX, &startY
    startPoint := {x: startX, y: startY}

    if (!HUMAN_MOUSE_ENABLED) {
        MouseMove targetPoint.x, targetPoint.y, 0
        return {points: [{x: targetPoint.x, y: targetPoint.y, sleepMs: 0, clickAfter: false, postClickPauseMs: 0}], steps: 1, durationMs: 0, distance: 0, overshootApplied: false, overshootClickApplied: false}
    }

    path := BuildHumanMousePath(startPoint, targetPoint, speedMultiplier, allowOvershootClick)
    if (path.points.Length = 0) {
        MouseMove targetPoint.x, targetPoint.y, 0
        return path
    }

    for point in path.points {
        MouseMove point.x, point.y, 0
        if (point.sleepMs > 0) {
            Sleep point.sleepMs
        }
        if (point.clickAfter) {
            Click
            if (point.postClickPauseMs > 0) {
                Sleep point.postClickPauseMs
            }
        }
    }

    MouseMove targetPoint.x, targetPoint.y, 0
    return path
}

BuildHumanMousePath(startPoint, targetPoint, speedMultiplier := "", allowOvershootClick := false) {
    global HUMAN_MOUSE_MIN_DURATION_MS, HUMAN_MOUSE_MAX_DURATION_MS, HUMAN_MOUSE_MS_PER_PIXEL
    global HUMAN_MOUSE_PIXELS_PER_STEP, HUMAN_MOUSE_MIN_STEPS, HUMAN_MOUSE_MAX_STEPS
    global HUMAN_MOUSE_DURATION_JITTER_PERCENT, HUMAN_MOUSE_STEP_DELAY_JITTER_PERCENT

    speedFactor := (speedMultiplier = "") ? 1.0 : speedMultiplier
    minDurationMs := Max(Round(HUMAN_MOUSE_MIN_DURATION_MS * speedFactor), 1)
    maxDurationMs := Max(Round(HUMAN_MOUSE_MAX_DURATION_MS * speedFactor), minDurationMs)
    msPerPixel := HUMAN_MOUSE_MS_PER_PIXEL * speedFactor
    deltaX := targetPoint.x - startPoint.x
    deltaY := targetPoint.y - startPoint.y
    distance := Sqrt(deltaX * deltaX + deltaY * deltaY)

    if (distance < 1) {
        return {points: [], steps: 0, durationMs: 0, distance: 0, overshootApplied: false, overshootClickApplied: false}
    }

    overshootPoint := BuildMouseOvershootPoint(startPoint, targetPoint, deltaX, deltaY, distance)
    moveTarget := IsObject(overshootPoint) ? overshootPoint : targetPoint
    moveDeltaX := moveTarget.x - startPoint.x
    moveDeltaY := moveTarget.y - startPoint.y
    moveDistance := Sqrt(moveDeltaX * moveDeltaX + moveDeltaY * moveDeltaY)
    controlPoints := BuildHumanMouseControlPoints(startPoint, moveTarget, moveDeltaX, moveDeltaY, moveDistance)
    baseDuration := ClampNumber(Round(distance * msPerPixel), minDurationMs, maxDurationMs)
    durationMs := GetRandomizedDelay(baseDuration, minDurationMs, HUMAN_MOUSE_DURATION_JITTER_PERCENT)

    rawSteps := Round((moveDistance / HUMAN_MOUSE_PIXELS_PER_STEP) + Random(-1, 2))
    steps := ClampNumber(rawSteps, HUMAN_MOUSE_MIN_STEPS, HUMAN_MOUSE_MAX_STEPS)

    points := []
    previousX := startPoint.x
    previousY := startPoint.y

    Loop steps {
        progress := A_Index / steps
        easedProgress := EaseInOutCubic(progress)
        bezierPoint := EvaluateCubicBezierPoint(startPoint, controlPoints.cp1, controlPoints.cp2, moveTarget, easedProgress)
        pointX := Round(bezierPoint.x)
        pointY := Round(bezierPoint.y)

        if (A_Index = steps) {
            pointX := moveTarget.x
            pointY := moveTarget.y
        }

        if (pointX = previousX && pointY = previousY) {
            continue
        }

        points.Push({x: pointX, y: pointY, sleepMs: 0, clickAfter: false, postClickPauseMs: 0})
        previousX := pointX
        previousY := pointY
    }

    if (points.Length = 0) {
        points.Push({x: moveTarget.x, y: moveTarget.y, sleepMs: 0, clickAfter: false, postClickPauseMs: 0})
    }

    movingPointCount := Max(points.Length - 1, 1)
    baseStepDelay := Max(Round(durationMs / movingPointCount), 1)

    Loop points.Length {
        if (A_Index = points.Length) {
            points[A_Index].sleepMs := 0
        } else {
            points[A_Index].sleepMs := GetRandomizedDelay(baseStepDelay, 1, HUMAN_MOUSE_STEP_DELAY_JITTER_PERCENT)
        }
    }

    correctionDurationMs := 0
    overshootClickPauseMs := 0
    overshootClickApplied := false
    if (IsObject(overshootPoint)) {
        overshootClickPauseMs := allowOvershootClick ? MaybeApplyMouseOvershootClickMarker(&points) : 0
        overshootClickApplied := overshootClickPauseMs > 0
        correctionDurationMs := AppendMouseOvershootCorrection(&points, overshootPoint, targetPoint)
    }

    return {
        points: points,
        steps: points.Length,
        durationMs: durationMs + overshootClickPauseMs + correctionDurationMs,
        distance: Round(distance),
        overshootApplied: IsObject(overshootPoint),
        overshootClickApplied: overshootClickApplied
    }
}

SleepWithHumanMouseActivity(totalDelay) {
    global HUMAN_MOUSE_ENABLED, HUMAN_MOUSE_IDLE_DURING_SLEEP, HUMAN_MOUSE_IDLE_SLEEP_CHANCE
    global HUMAN_MOUSE_IDLE_SLEEP_MIN_DELAY_MS, HUMAN_MOUSE_IDLE_SLEEP_MAX_MOVES
    global HUMAN_MOUSE_IDLE_SLEEP_PAUSE_MIN_MS, HUMAN_MOUSE_IDLE_SLEEP_PAUSE_MAX_MS
    global HUMAN_MOUSE_IDLE_MOVE_BUFFER_MS
    global SAFE_KEYSTROKE_ENABLED, SAFE_KEYSTROKE_MIN_DELAY_MS
    global SAFE_KEYSTROKE_MAX_PRESSES_PER_SLEEP, SAFE_KEYSTROKE_HOLD_MAX_MS, SAFE_KEYSTROKE_POST_PRESS_MAX_MS

    if (totalDelay <= 0) {
        return
    }

    hasSafeKeystrokes := GetSafeKeystrokes().Length > 0
    allowKeyActivity := SAFE_KEYSTROKE_ENABLED && hasSafeKeystrokes && totalDelay >= SAFE_KEYSTROKE_MIN_DELAY_MS
    allowMouseActivity := HUMAN_MOUSE_ENABLED && HUMAN_MOUSE_IDLE_DURING_SLEEP && totalDelay >= HUMAN_MOUSE_IDLE_SLEEP_MIN_DELAY_MS
    if (!allowMouseActivity && !allowKeyActivity) {
        Sleep totalDelay
        return
    }

    if (!IsWarframeWindowActive()) {
        Sleep totalDelay
        return
    }

    performMouseWander := allowMouseActivity && Random(0.0, 1.0) <= HUMAN_MOUSE_IDLE_SLEEP_CHANCE
    remainingMs := totalDelay
    moveCount := performMouseWander ? GetHumanSleepIdleMoveCount(totalDelay) : 0
    activityLoopCount := Max(moveCount, allowKeyActivity ? SAFE_KEYSTROKE_MAX_PRESSES_PER_SLEEP : 0, 1)
    safeKeystrokesSent := 0

    Loop activityLoopCount {
        if (remainingMs <= 0) {
            break
        }

        remainingMoves := Max(moveCount - A_Index + 1, 0)
        currentLoopHasMove := performMouseWander && A_Index <= moveCount
        reservedForUpcomingMoves := Max(remainingMoves - (currentLoopHasMove ? 1 : 0), 0) * HUMAN_MOUSE_IDLE_MOVE_BUFFER_MS
        currentMoveBufferMs := currentLoopHasMove ? HUMAN_MOUSE_IDLE_MOVE_BUFFER_MS : 0
        if (allowKeyActivity && safeKeystrokesSent < SAFE_KEYSTROKE_MAX_PRESSES_PER_SLEEP) {
            currentKeyBufferMs := SAFE_KEYSTROKE_HOLD_MAX_MS + SAFE_KEYSTROKE_POST_PRESS_MAX_MS
        } else {
            currentKeyBufferMs := 0
        }
        availablePauseMs := remainingMs - currentMoveBufferMs - currentKeyBufferMs - reservedForUpcomingMoves
        if (availablePauseMs <= 0) {
            break
        }

        pauseMs := ClampNumber(
            Random(HUMAN_MOUSE_IDLE_SLEEP_PAUSE_MIN_MS, HUMAN_MOUSE_IDLE_SLEEP_PAUSE_MAX_MS),
            1,
            availablePauseMs
        )
        Sleep pauseMs
        remainingMs -= pauseMs

        if (!IsWarframeWindowActive()) {
            break
        }

        MaybeSendRandomSafeKeystroke(&remainingMs, &safeKeystrokesSent)

        if (currentLoopHasMove && remainingMs > HUMAN_MOUSE_IDLE_MOVE_BUFFER_MS) {
            wanderTarget := BuildIdleMouseWanderTarget()
            speedMultiplier := GetIdleMouseSpeedMultiplier()
            movementMeta := MoveMouseHumanized(wanderTarget, speedMultiplier)
            remainingMs := Max(remainingMs - movementMeta.durationMs, 0)
        }

        MaybeSendRandomSafeKeystroke(&remainingMs, &safeKeystrokesSent)
    }

    if (remainingMs > 0) {
        Sleep remainingMs
    }
}

SleepRandomized(baseDelay, minimumDelay := 0, jitterPercent := "") {
    SleepWithHumanMouseActivity(GetRandomizedDelay(baseDelay, minimumDelay, jitterPercent))
}

MaybeSendRandomSafeKeystroke(&remainingMs, &safeKeystrokesSent) {
    global SAFE_KEYSTROKE_ENABLED, SAFE_KEYSTROKE_PRESS_CHANCE, SAFE_KEYSTROKE_MAX_PRESSES_PER_SLEEP
    global SAFE_KEYSTROKE_HOLD_MIN_MS, SAFE_KEYSTROKE_POST_PRESS_MIN_MS, SAFE_KEYSTROKE_POST_PRESS_MAX_MS

    if (!SAFE_KEYSTROKE_ENABLED || safeKeystrokesSent >= SAFE_KEYSTROKE_MAX_PRESSES_PER_SLEEP) {
        return false
    }

    if (!IsWarframeWindowActive() || remainingMs < (SAFE_KEYSTROKE_HOLD_MIN_MS + SAFE_KEYSTROKE_POST_PRESS_MIN_MS)) {
        return false
    }

    if (Random(0.0, 1.0) > SAFE_KEYSTROKE_PRESS_CHANCE) {
        return false
    }

    keySpec := GetRandomSafeKeystroke()
    if (keySpec = "") {
        return false
    }

    holdMs := ClampNumber(GetRandomSafeKeystrokeHoldDuration(), 0, remainingMs)
    remainingMs := Max(remainingMs - SendSafeKeystroke(keySpec, holdMs), 0)
    safeKeystrokesSent += 1

    settleMs := ClampNumber(
        Random(SAFE_KEYSTROKE_POST_PRESS_MIN_MS, SAFE_KEYSTROKE_POST_PRESS_MAX_MS),
        0,
        remainingMs
    )
    if (settleMs > 0) {
        Sleep settleMs
        remainingMs -= settleMs
    }

    return true
}

GetHumanSleepIdleMoveCount(totalDelay) {
    global HUMAN_MOUSE_IDLE_SLEEP_MAX_MOVES

    rawCount := Round((totalDelay / 1100) + Random(0, 1))
    return ClampNumber(rawCount, 1, HUMAN_MOUSE_IDLE_SLEEP_MAX_MOVES)
}

BuildIdleMouseWanderTarget() {
    MouseGetPos &originX, &originY
    bounds := GetActiveMouseWindowBounds()
    distancePx := GetIdleMouseWanderDistance()
    angleRadians := Random(0.0, 6.283185307179586)
    return BuildIdleMouseWanderTargetFromOrigin({x: originX, y: originY}, bounds, distancePx, angleRadians)
}

BuildIdleMouseWanderTargetFromOrigin(originPoint, bounds, distancePx, angleRadians) {
    targetX := Round(originPoint.x + (Cos(angleRadians) * distancePx))
    targetY := Round(originPoint.y + (Sin(angleRadians) * distancePx))
    return {
        x: ClampNumber(targetX, bounds.minX, bounds.maxX),
        y: ClampNumber(targetY, bounds.minY, bounds.maxY)
    }
}

GetIdleMouseWanderDistance() {
    global HUMAN_MOUSE_IDLE_NEAR_MOVE_CHANCE
    global HUMAN_MOUSE_IDLE_NEAR_MIN_PX, HUMAN_MOUSE_IDLE_NEAR_MAX_PX
    global HUMAN_MOUSE_IDLE_FAR_MIN_PX, HUMAN_MOUSE_IDLE_FAR_MAX_PX

    if (Random(0.0, 1.0) <= HUMAN_MOUSE_IDLE_NEAR_MOVE_CHANCE) {
        return Random(HUMAN_MOUSE_IDLE_NEAR_MIN_PX, HUMAN_MOUSE_IDLE_NEAR_MAX_PX)
    }

    return Random(HUMAN_MOUSE_IDLE_FAR_MIN_PX, HUMAN_MOUSE_IDLE_FAR_MAX_PX)
}

GetIdleMouseSpeedMultiplier() {
    global HUMAN_MOUSE_IDLE_FAST_MOVE_CHANCE
    global HUMAN_MOUSE_IDLE_FAST_SPEED_MIN, HUMAN_MOUSE_IDLE_FAST_SPEED_MAX
    global HUMAN_MOUSE_IDLE_SLOW_SPEED_MIN, HUMAN_MOUSE_IDLE_SLOW_SPEED_MAX

    if (Random(0.0, 1.0) <= HUMAN_MOUSE_IDLE_FAST_MOVE_CHANCE) {
        return Random(HUMAN_MOUSE_IDLE_FAST_SPEED_MIN, HUMAN_MOUSE_IDLE_FAST_SPEED_MAX)
    }

    return Random(HUMAN_MOUSE_IDLE_SLOW_SPEED_MIN, HUMAN_MOUSE_IDLE_SLOW_SPEED_MAX)
}

GetSafeKeystrokes() {
    global SAFE_KEYSTROKES

    keys := []
    for key in SAFE_KEYSTROKES {
        keys.Push(key)
    }
    return keys
}

GetRandomSafeKeystroke() {
    keys := GetSafeKeystrokes()
    if (keys.Length = 0) {
        return ""
    }

    return keys[Random(1, keys.Length)]
}

GetRandomSafeKeystrokeHoldDuration() {
    global SAFE_KEYSTROKE_HOLD_MIN_MS, SAFE_KEYSTROKE_HOLD_MAX_MS

    maxHoldMs := Max(SAFE_KEYSTROKE_HOLD_MAX_MS, SAFE_KEYSTROKE_HOLD_MIN_MS)
    return Random(SAFE_KEYSTROKE_HOLD_MIN_MS, maxHoldMs)
}

BuildSafeKeySendToken(keySpec) {
    static punctuationTokenMap := Map(
        "``", "vkC0",
        "-", "vkBD",
        "=", "vkBB",
        "[", "vkDB",
        "]", "vkDD",
        "\", "vkDC",
        ";", "vkBA",
        "'", "vkDE",
        ",", "vkBC",
        ".", "vkBE",
        "/", "vkBF"
    )

    if (keySpec = "") {
        return ""
    }

    if (RegExMatch(keySpec, "^\{(.+)\}$", &match)) {
        return match[1]
    }

    if (StrLen(keySpec) = 1) {
        if (punctuationTokenMap.Has(keySpec)) {
            return punctuationTokenMap[keySpec]
        }

        upperChar := StrUpper(keySpec)
        charCode := Ord(upperChar)
        if ((charCode >= 48 && charCode <= 57) || (charCode >= 65 && charCode <= 90)) {
            return Format("vk{:02X}", charCode)
        }
    }

    return ""
}

SendSafeKeystroke(keySpec, holdMs := "") {
    sendToken := BuildSafeKeySendToken(keySpec)
    if (sendToken = "") {
        return 0
    }

    actualHoldMs := (holdMs = "") ? GetRandomSafeKeystrokeHoldDuration() : Max(holdMs, 0)
    SendEvent "{" . sendToken . " down}"
    if (actualHoldMs > 0) {
        Sleep actualHoldMs
    }
    SendEvent "{" . sendToken . " up}"

    return actualHoldMs
}

GetActiveMouseWindowBounds() {
    activeHwnd := WinActive("A")
    if (!activeHwnd) {
        return {
            minX: 2,
            minY: 2,
            maxX: Max(A_ScreenWidth - 3, 2),
            maxY: Max(A_ScreenHeight - 3, 2)
        }
    }

    WinGetPos(&windowX, &windowY, &windowWidth, &windowHeight, "ahk_id " . activeHwnd)
    return {
        minX: 2,
        minY: 2,
        maxX: Max(windowWidth - 3, 2),
        maxY: Max(windowHeight - 3, 2)
    }
}

BuildHumanMouseControlPoints(startPoint, targetPoint, deltaX, deltaY, distance) {
    global HUMAN_MOUSE_CURVE_STRENGTH, HUMAN_MOUSE_CURVE_MAX_OFFSET_PX

    normalX := -deltaY / distance
    normalY := deltaX / distance
    control1Progress := Random(0.18, 0.34)
    control2Progress := Random(0.60, 0.84)
    curveSide := (Random(0, 1) = 0) ? -1 : 1
    curveOffsetBase := Min(HUMAN_MOUSE_CURVE_MAX_OFFSET_PX, Max(2, distance * HUMAN_MOUSE_CURVE_STRENGTH))
    controlOffset1 := curveSide * curveOffsetBase * Random(0.55, 1.00)
    controlOffset2 := curveSide * curveOffsetBase * Random(0.25, 0.80)

    return {
        cp1: {
            x: startPoint.x + (deltaX * control1Progress) + (normalX * controlOffset1),
            y: startPoint.y + (deltaY * control1Progress) + (normalY * controlOffset1)
        },
        cp2: {
            x: startPoint.x + (deltaX * control2Progress) + (normalX * controlOffset2),
            y: startPoint.y + (deltaY * control2Progress) + (normalY * controlOffset2)
        }
    }
}

BuildMouseOvershootPoint(startPoint, targetPoint, deltaX, deltaY, distance) {
    global HUMAN_MOUSE_OVERSHOOT_CHANCE, HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE
    global HUMAN_MOUSE_OVERSHOOT_MIN_PX, HUMAN_MOUSE_OVERSHOOT_MAX_PX, HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX

    if (distance < HUMAN_MOUSE_OVERSHOOT_MIN_DISTANCE) {
        return ""
    }

    if (Random(0.0, 1.0) > HUMAN_MOUSE_OVERSHOOT_CHANCE) {
        return ""
    }

    overshootDistance := Random(HUMAN_MOUSE_OVERSHOOT_MIN_PX, HUMAN_MOUSE_OVERSHOOT_MAX_PX)
    lateralOffset := Random(-HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX, HUMAN_MOUSE_OVERSHOOT_LATERAL_JITTER_PX)
    directionX := deltaX / distance
    directionY := deltaY / distance
    normalX := -directionY
    normalY := directionX

    return {
        x: Round(targetPoint.x + (directionX * overshootDistance) + (normalX * lateralOffset)),
        y: Round(targetPoint.y + (directionY * overshootDistance) + (normalY * lateralOffset))
    }
}

AppendMouseOvershootCorrection(&points, overshootPoint, targetPoint) {
    global HUMAN_MOUSE_OVERSHOOT_CORRECTION_MIN_MS, HUMAN_MOUSE_OVERSHOOT_CORRECTION_MAX_MS

    correctionDeltaX := targetPoint.x - overshootPoint.x
    correctionDeltaY := targetPoint.y - overshootPoint.y
    correctionDistance := Sqrt(correctionDeltaX * correctionDeltaX + correctionDeltaY * correctionDeltaY)
    if (correctionDistance < 1) {
        return 0
    }

    correctionSteps := ClampNumber(Round((correctionDistance / 5) + Random(0, 2)), 2, 5)
    correctionDuration := Random(HUMAN_MOUSE_OVERSHOOT_CORRECTION_MIN_MS, HUMAN_MOUSE_OVERSHOOT_CORRECTION_MAX_MS)
    correctionStepDelay := Max(Round(correctionDuration / correctionSteps), 1)
    totalSleepMs := 0

    Loop correctionSteps {
        progress := A_Index / correctionSteps
        easedProgress := EaseOutCubic(progress)
        pointX := Round(overshootPoint.x + (correctionDeltaX * easedProgress))
        pointY := Round(overshootPoint.y + (correctionDeltaY * easedProgress))

        if (A_Index = correctionSteps) {
            pointX := targetPoint.x
            pointY := targetPoint.y
        }

        lastPoint := points[points.Length]
        if (pointX = lastPoint.x && pointY = lastPoint.y) {
            continue
        }

        points.Push({
            x: pointX,
            y: pointY,
            sleepMs: (A_Index = correctionSteps) ? 0 : correctionStepDelay,
            clickAfter: false,
            postClickPauseMs: 0
        })

        if (A_Index != correctionSteps) {
            totalSleepMs += correctionStepDelay
        }
    }

    return totalSleepMs
}

MaybeApplyMouseOvershootClickMarker(&points) {
    global HUMAN_MOUSE_OVERSHOOT_CLICK_CHANCE
    global HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MIN_MS, HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MAX_MS

    if (points.Length = 0) {
        return 0
    }

    if (Random(0.0, 1.0) > HUMAN_MOUSE_OVERSHOOT_CLICK_CHANCE) {
        return 0
    }

    pauseMs := Random(HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MIN_MS, Max(HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MAX_MS, HUMAN_MOUSE_OVERSHOOT_CLICK_PAUSE_MIN_MS))
    points[points.Length].clickAfter := true
    points[points.Length].postClickPauseMs := pauseMs
    return pauseMs
}

EvaluateCubicBezierPoint(startPoint, controlPoint1, controlPoint2, targetPoint, t) {
    inverseT := 1 - t
    inverseT2 := inverseT * inverseT
    inverseT3 := inverseT2 * inverseT
    t2 := t * t
    t3 := t2 * t

    return {
        x: (inverseT3 * startPoint.x)
            + (3 * inverseT2 * t * controlPoint1.x)
            + (3 * inverseT * t2 * controlPoint2.x)
            + (t3 * targetPoint.x),
        y: (inverseT3 * startPoint.y)
            + (3 * inverseT2 * t * controlPoint1.y)
            + (3 * inverseT * t2 * controlPoint2.y)
            + (t3 * targetPoint.y)
    }
}

EaseInOutCubic(t) {
    if (t < 0.5) {
        return 4 * t * t * t
    }

    inverse := -2 * t + 2
    return 1 - ((inverse * inverse * inverse) / 2)
}

EaseOutCubic(t) {
    inverse := 1 - t
    return 1 - (inverse * inverse * inverse)
}

IsWarframeWindowActive() {
    return WinActive("ahk_exe Warframe.x64.exe") || WinActive("Warframe")
}

EnsureWarframeWindow() {
    if (IsWarframeWindowActive()) {
        return true
    }

    if (ActivateWarframeWindow("ahk_exe Warframe.x64.exe")) {
        return true
    }
    if (ActivateWarframeWindow("Warframe")) {
        return true
    }

    return false
}

ActivateWarframeWindow(windowCriteria) {
    hwnd := WinExist(windowCriteria)
    if (!hwnd) {
        return false
    }

    windowRef := "ahk_id " . hwnd
    WinActivate(windowRef)
    WinWaitActive(windowRef, , 1)
    return WinActive(windowRef)
}
