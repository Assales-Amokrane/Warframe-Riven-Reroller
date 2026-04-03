; --------------------------------------------------------------------
; ===== RIVEN ATTRIBUTE READING =====
; --------------------------------------------------------------------

ReadRivenAttributes(readContext := "") {
    global LOG_VERBOSE_OCR, CAPTURE_NEW_RIVEN_READS, OCR_MIN_INDEPENDENT_READS

    area := GetActionCoord("rivenAttributes")
    width := area.x2 - area.x1
    height := area.y2 - area.y1

    if (width <= 0 || height <= 0) {
        return {error: "Invalid riven attribute area coordinates"}
    }

    hBitmap := ""
    try {
        hBitmap := OCR.CreateHBitmap(area.x1, area.y1, width, height)
    } catch as err {
        return {error: "Unable to capture riven attribute area: " . err.Message}
    }

    if (CAPTURE_NEW_RIVEN_READS && readContext = "new") {
        capturePath := CaptureRivenAttributeAreaScreenshot(readContext, hBitmap)
        if (capturePath != "") {
            LogEvent("INFO", "AttributeAreaCaptured", {context: readContext, path: capturePath})
        }
    }

    attempts := BuildOcrAttemptPlan(OCR_MIN_INDEPENDENT_READS)

    attemptResults := []
    uniqueAttemptLogKeys := Map()

    for attemptIndex, options in attempts {
        try {
            attemptBitmap := attemptIndex = 1 ? hBitmap : OCR.CreateHBitmap(area.x1, area.y1, width, height)
            if (!ApplyStandardOcrPreprocessing(attemptBitmap)) {
                throw Error("Failed to preprocess capture for OCR.")
            }

            ocrResult := OCR.FromBitmap(attemptBitmap, {
                lang: options.lang,
                scale: options.scale
            })
            lines := ReconstructAttributeLines(ocrResult)
            parsed := ParseRivenAttributes(lines, ocrResult.Text)
            score := ScoreParsedAttributes(parsed)
            signature := BuildParsedSignature(parsed)
            mappedCount := CountMappedAttributes(parsed)
            attemptResults.Push({
                name: options.name,
                score: score,
                signature: signature,
                mappedCount: mappedCount,
                parsed: parsed
            })

            if (LOG_VERBOSE_OCR) {
                compactText := Trim(RegExReplace(ocrResult.Text, "\s+", " "))
                logKey := options.name . "|" . signature . "|" . compactText
                if (!uniqueAttemptLogKeys.Has(logKey)) {
                    uniqueAttemptLogKeys[logKey] := true
                    LogEvent("INFO", "OcrAttempt", {
                        pass: options.name,
                        score: score,
                        count: parsed.count,
                        mapped: mappedCount,
                        lines: lines.Length,
                        text: SubStr(compactText, 1, 160)
                    })
                }
            }
        } catch as err {
            errData := {pass: options.name, message: err.Message}
            if (err.HasProp("What") && err.What != "") {
                errData.what := err.What
            }
            if (err.HasProp("File") && err.File != "") {
                errData.file := err.File
            }
            if (err.HasProp("Line")) {
                errData.line := err.Line
            }
            LogEvent("WARN", "OcrAttemptFailed", errData)
        }
    }

    if (attemptResults.Length = 0) {
        return {error: "Unable to OCR riven attributes"}
    }

    selected := SelectBestParsedAttempt(attemptResults)
    if (LOG_VERBOSE_OCR && attemptResults.Length > 1) {
        LogEvent("INFO", "OcrSelected", {
            pass: selected.name,
            votes: selected.votes,
            score: selected.score,
            mapped: selected.mappedCount,
            count: selected.parsed.count
        })
    }

    reliableByVotes := selected.votes >= OCR_MIN_INDEPENDENT_READS
    hasAttributes := selected.parsed.count > 0
    isReliable := reliableByVotes && hasAttributes

    selected.parsed.selectedPass := selected.name
    selected.parsed.voteCount := selected.votes
    selected.parsed.requiredVotes := OCR_MIN_INDEPENDENT_READS
    selected.parsed.mappedCount := selected.mappedCount
    selected.parsed.signature := selected.signature
    selected.parsed.isReliable := isReliable

    readSummary := BuildParsedReadSummary(selected.parsed)
    compactRaw := Trim(RegExReplace(selected.parsed.raw, "\s+", " "))
    context := readContext = "" ? "unknown" : readContext

    LogEvent("INFO", "RivenRead", {
        context: context,
        reliable: isReliable ? "yes" : "no",
        votes: selected.votes,
        requiredVotes: OCR_MIN_INDEPENDENT_READS,
        pass: selected.name,
        count: selected.parsed.count,
        mapped: selected.mappedCount,
        attrs: readSummary,
        raw: SubStr(compactRaw, 1, 200)
    })
    PrintStatus(
        "Read " . context
        . " | " . (isReliable ? "reliable" : "unreliable")
        . " " . selected.votes . "/" . OCR_MIN_INDEPENDENT_READS
        . " | " . readSummary
    )

    if (!isReliable) {
        if (!reliableByVotes) {
            reason := "Unreliable OCR read (" . selected.votes . "/" . OCR_MIN_INDEPENDENT_READS . " agreement)"
        } else {
            reason := "Unreliable OCR read (no attributes parsed)"
        }
        return {error: reason, read: selected.parsed}
    }

    return selected.parsed
}

BuildOcrAttemptPlan(requiredVotes) {
    attemptCount := Max(3, requiredVotes)
    attempts := []
    Loop attemptCount {
        attempts.Push({
            name: "read-" . A_Index,
            lang: "en",
            scale: 2.0
        })
    }
    return attempts
}

ApplyStandardOcrPreprocessing(hBitmap) {
    global OCR_BRIGHTNESS_BOOST, OCR_SHARPEN_ENABLED

    hBitmapPtr := ResolveHBitmapPointer(hBitmap)
    if (!hBitmapPtr) {
        return false
    }
    if (!EnsureGdiPlusToken()) {
        return false
    }

    pBitmap := 0
    status := DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hBitmapPtr, "Ptr", 0, "Ptr*", &pBitmap, "UInt")
    if (status != 0 || !pBitmap) {
        return false
    }

    rect := Buffer(16, 0)
    bitmapData := Buffer(16 + (A_PtrSize * 2), 0)
    locked := false
    success := false

    try {
        width := 0
        height := 0
        DllCall("gdiplus\GdipGetImageWidth", "Ptr", pBitmap, "UInt*", &width, "UInt")
        DllCall("gdiplus\GdipGetImageHeight", "Ptr", pBitmap, "UInt*", &height, "UInt")
        if (width <= 0 || height <= 0) {
            return false
        }

        NumPut("Int", 0, rect, 0)
        NumPut("Int", 0, rect, 4)
        NumPut("Int", width, rect, 8)
        NumPut("Int", height, rect, 12)

        lockModeReadWrite := 3
        pixelFormat32bppArgb := 0x26200A
        status := DllCall(
            "gdiplus\GdipBitmapLockBits",
            "Ptr", pBitmap,
            "Ptr", rect,
            "UInt", lockModeReadWrite,
            "Int", pixelFormat32bppArgb,
            "Ptr", bitmapData,
            "UInt"
        )
        if (status != 0) {
            return false
        }
        locked := true

        stride := NumGet(bitmapData, 8, "Int")
        scan0 := NumGet(bitmapData, 16, "Ptr")
        if (!scan0 || stride = 0) {
            return false
        }

        pixelCount := width * height
        src := []
        src.Length := pixelCount
        out := []
        out.Length := pixelCount

        y := 0
        while (y < height) {
            rowPtr := ResolveRowPointer(scan0, stride, height, y)
            x := 0
            while (x < width) {
                pixelPtr := rowPtr + (x * 4)
                b := NumGet(pixelPtr, "UChar")
                g := NumGet(pixelPtr + 1, "UChar")
                r := NumGet(pixelPtr + 2, "UChar")

                gray := Round((r * 299 + g * 587 + b * 114) / 1000)
                inverted := 255 - gray

                idx := (y * width) + x + 1
                src[idx] := inverted
                out[idx] := inverted
                x++
            }
            y++
        }

        if (OCR_SHARPEN_ENABLED && width > 2 && height > 2) {
            y := 1
            while (y < height - 1) {
                x := 1
                while (x < width - 1) {
                    idx := (y * width) + x + 1
                    sharpened := (src[idx] * 5) - src[idx - 1] - src[idx + 1] - src[idx - width] - src[idx + width]
                    out[idx] := ClampByte(sharpened)
                    x++
                }
                y++
            }
        }

        y := 0
        while (y < height) {
            rowPtr := ResolveRowPointer(scan0, stride, height, y)
            x := 0
            while (x < width) {
                idx := (y * width) + x + 1
                value := out[idx]
                value := ClampByte(value + OCR_BRIGHTNESS_BOOST)
                pixelPtr := rowPtr + (x * 4)
                NumPut("UChar", value, pixelPtr, 0)
                NumPut("UChar", value, pixelPtr, 1)
                NumPut("UChar", value, pixelPtr, 2)
                NumPut("UChar", 255, pixelPtr, 3)
                x++
            }
            y++
        }

        success := true
    } finally {
        if (locked) {
            DllCall("gdiplus\GdipBitmapUnlockBits", "Ptr", pBitmap, "Ptr", bitmapData, "UInt")
        }
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
    }

    return success
}

ResolveRowPointer(scan0, stride, height, y) {
    if (stride >= 0) {
        return scan0 + (y * stride)
    }
    return scan0 + ((height - 1 - y) * Abs(stride))
}

ClampByte(value) {
    if (value < 0) {
        return 0
    }
    if (value > 255) {
        return 255
    }
    return Round(value)
}

ResolveHBitmapPointer(hBitmap) {
    if (IsObject(hBitmap) && hBitmap.HasProp("ptr")) {
        return hBitmap.ptr
    }
    return hBitmap
}

CaptureRivenAttributeAreaScreenshot(readContext := "new", hBitmap := "") {
    global ATTRIBUTE_CAPTURE_DIR, CURRENT_CYCLE, ACTIVE_PROFILE

    area := GetActionCoord("rivenAttributes")
    width := area.x2 - area.x1
    height := area.y2 - area.y1
    if (width <= 0 || height <= 0) {
        LogEvent("WARN", "AttributeAreaCaptureSkipped", {reason: "InvalidArea", width: width, height: height})
        return ""
    }

    EnsureDirectory(ATTRIBUTE_CAPTURE_DIR)

    profilePart := "no-profile"
    if (ACTIVE_PROFILE.HasOwnProp("profileId") && ACTIVE_PROFILE.profileId != "") {
        profilePart := Slugify(ACTIVE_PROFILE.profileId)
    }

    timestamp := FormatTime(, "yyyyMMdd-HHmmss")
    unique := Format("{:03}", A_MSec)
    fileName := profilePart . "-cycle-" . CURRENT_CYCLE . "-" . readContext . "-" . timestamp . "-" . unique . ".png"
    filePath := ATTRIBUTE_CAPTURE_DIR "\" . fileName

    try {
        if (!(IsObject(hBitmap) || hBitmap)) {
            hBitmap := OCR.CreateHBitmap(area.x1, area.y1, width, height)
        }
        if (!SaveHBitmapAsPng(hBitmap, filePath)) {
            LogEvent("WARN", "AttributeAreaCaptureFailed", {reason: "SaveFailed", path: filePath})
            return ""
        }
    } catch as err {
        LogEvent("WARN", "AttributeAreaCaptureFailed", {reason: err.Message})
        return ""
    }

    return filePath
}

CountMappedAttributes(parsed) {
    if (!parsed.HasOwnProp("attributes")) {
        return 0
    }

    mapped := 0
    for attr in parsed.attributes {
        if (attr.HasOwnProp("isMapped") && attr.isMapped) {
            mapped++
        }
    }
    return mapped
}

BuildParsedSignature(parsed) {
    if (!parsed.HasOwnProp("attributes") || parsed.attributes.Length = 0) {
        return "none"
    }

    parts := []
    for attr in parsed.attributes {
        attrId := attr.HasOwnProp("attrId") ? attr.attrId : "unknown"
        polarity := attr.HasOwnProp("polarity") ? attr.polarity : "positive"
        parts.Push(polarity . ":" . attrId)
    }

    SortStringArray(parts)
    return JoinStringArray(parts, "|")
}

SelectBestParsedAttempt(attemptResults) {
    signatureVotes := Map()
    for result in attemptResults {
        votes := signatureVotes.Has(result.signature) ? signatureVotes[result.signature] + 1 : 1
        signatureVotes[result.signature] := votes
    }

    best := ""
    for result in attemptResults {
        votes := signatureVotes[result.signature]
        result.votes := votes

        if (!IsObject(best)) {
            best := result
            continue
        }

        isBetter := false
        if (votes > best.votes) {
            isBetter := true
        } else if (votes = best.votes && result.score > best.score) {
            isBetter := true
        } else if (votes = best.votes && result.score = best.score && result.mappedCount > best.mappedCount) {
            isBetter := true
        }

        if (isBetter) {
            best := result
        }
    }

    return best
}

JoinStringArray(arr, separator := ", ") {
    out := ""
    for index, value in arr {
        if (index > 1) {
            out .= separator
        }
        out .= value
    }
    return out
}

SortStringArray(arr) {
    for i, _ in arr {
        for j, _ in arr {
            if (j > i && StrCompare(arr[j], arr[i], false) < 0) {
                tmp := arr[i]
                arr[i] := arr[j]
                arr[j] := tmp
            }
        }
    }
}

BuildParsedReadSummary(parsed) {
    if (!parsed.HasOwnProp("attributes") || parsed.attributes.Length = 0) {
        return "no attributes"
    }

    parts := []
    for attr in parsed.attributes {
        symbol := attr.HasOwnProp("symbol") ? attr.symbol : "?"
        valueText := FormatAttributeDisplayValue(attr)
        label := attr.HasOwnProp("label") ? attr.label : (attr.HasOwnProp("raw") ? attr.raw : "unknown")
        parts.Push(symbol . valueText . " " . label)
    }
    return JoinStringArray(parts, " | ")
}

FormatAttributeDisplayValue(attr) {
    value := attr.HasOwnProp("value") ? attr.value : ""
    valueText := FormatAttributeValue(value)
    if (valueText = "?") {
        return valueText
    }

    if (ShouldDisplayPercent(attr)) {
        return valueText . "%"
    }

    return valueText
}

ShouldDisplayPercent(attr) {
    symbol := attr.HasOwnProp("symbol") ? StrLower(attr.symbol) : ""
    if (symbol = "x") {
        return false
    }

    if (attr.HasOwnProp("hasPercent") && attr.hasPercent) {
        return true
    }

    attrId := attr.HasOwnProp("attrId") ? attr.attrId : ""
    return AttributeLikelyPercent(attrId)
}

AttributeLikelyPercent(attrId) {
    if (attrId = "" || RegExMatch(attrId, "^unknown-")) {
        return false
    }
    if (RegExMatch(attrId, "^damage-to-")) {
        return false
    }

    nonPercent := Map(
        "punch-through", true,
        "range", true,
        "initial-combo", true,
        "combo-duration", true
    )
    return !nonPercent.Has(attrId)
}

FormatAttributeValue(value) {
    numeric := CoerceNumber(value, "")
    if (numeric = "") {
        return "?"
    }

    rounded := Round(numeric, 2)
    if (Abs(rounded - Round(rounded, 0)) < 0.000001) {
        return Round(rounded, 0) . ""
    }

    text := Format("{:.2f}", rounded)
    text := RegExReplace(text, "0+$", "")
    text := RegExReplace(text, "\.$", "")
    return text
}

EnsureGdiPlusToken() {
    static gdipToken := 0
    if (!gdipToken) {
        startupInput := Buffer(16 + (A_PtrSize * 2), 0)
        NumPut("UInt", 1, startupInput, 0)
        status := DllCall("gdiplus\GdiplusStartup", "UPtr*", &gdipToken, "Ptr", startupInput, "Ptr", 0, "UInt")
        if (status != 0) {
            return 0
        }
    }
    return gdipToken
}

SaveHBitmapAsPng(hBitmap, outputPath) {
    static pngClsid := GetPngEncoderClsid()

    if (!EnsureGdiPlusToken()) {
        return false
    }

    hBitmapPtr := ResolveHBitmapPointer(hBitmap)
    if (!hBitmapPtr) {
        return false
    }

    pBitmap := 0
    status := DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hBitmapPtr, "Ptr", 0, "Ptr*", &pBitmap, "UInt")
    if (status != 0 || !pBitmap) {
        return false
    }

    saveStatus := DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBitmap, "WStr", outputPath, "Ptr", pngClsid.Ptr, "Ptr", 0, "UInt")
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)

    return saveStatus = 0
}

GetPngEncoderClsid() {
    static clsid := Buffer(16, 0)
    static initialized := false
    if (!initialized) {
        DllCall("ole32\CLSIDFromString", "WStr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "Ptr", clsid, "UInt")
        initialized := true
    }
    return clsid
}

ScoreParsedAttributes(parsed) {
    if (!parsed.HasOwnProp("attributes")) {
        return 0
    }

    score := parsed.attributes.Length * 2
    mapped := 0
    for attr in parsed.attributes {
        if (attr.HasOwnProp("isMapped") && attr.isMapped) {
            mapped++
        }
    }
    score += mapped * 3
    return score
}

ReconstructAttributeLines(ocrResult) {
    if (!ocrResult.HasProp("Words") || ocrResult.Words.Length = 0) {
        return StrSplit(ocrResult.Text, "`n", "`r")
    }

    words := []
    totalHeight := 0
    for word in ocrResult.Words {
        text := Trim(word.Text)
        if (text = "") {
            continue
        }

        x := CoerceNumber(word.x, "")
        y := CoerceNumber(word.y, "")
        w := CoerceNumber(word.w, "")
        h := CoerceNumber(word.h, "")
        if (x = "" || y = "" || w = "" || h = "") {
            continue
        }

        words.Push({
            text: text,
            x: x,
            y: y,
            w: w,
            h: h
        })
        totalHeight += Max(1, h)
    }

    if (words.Length = 0) {
        return StrSplit(ocrResult.Text, "`n", "`r")
    }

    SortWordEntries(words)
    tolerance := Max(8, Round((totalHeight / words.Length) * 0.6))

    lineGroups := []
    for word in words {
        matchedIndex := 0
        for index, line in lineGroups {
            if (Abs(word.y - line.avgY) <= tolerance) {
                matchedIndex := index
                break
            }
        }

        if (matchedIndex = 0) {
            lineGroups.Push({avgY: word.y, words: [word]})
        } else {
            target := lineGroups[matchedIndex]
            target.words.Push(word)
            target.avgY := Round((target.avgY + word.y) / 2)
            lineGroups[matchedIndex] := target
        }
    }

    SortLineGroups(lineGroups)

    lines := []
    for line in lineGroups {
        SortWordsByX(line.words)
        text := ""
        for word in line.words {
            text .= (text = "" ? "" : " ") . word.text
        }
        text := NormalizeLineText(text)
        if (text != "") {
            lines.Push(text)
        }
    }

    return lines
}

SortWordEntries(entries) {
    for i, _ in entries {
        for j, _ in entries {
            if (j <= i) {
                continue
            }

            yi := entries[i].y
            yj := entries[j].y
            xi := entries[i].x
            xj := entries[j].x

            shouldSwap := false
            if (Abs(yj - yi) <= 4) {
                shouldSwap := xj < xi
            } else {
                shouldSwap := yj < yi
            }

            if (shouldSwap) {
                tmp := entries[i]
                entries[i] := entries[j]
                entries[j] := tmp
            }
        }
    }
}

SortLineGroups(lineGroups) {
    for i, _ in lineGroups {
        for j, _ in lineGroups {
            if (j > i && lineGroups[j].avgY < lineGroups[i].avgY) {
                tmp := lineGroups[i]
                lineGroups[i] := lineGroups[j]
                lineGroups[j] := tmp
            }
        }
    }
}

SortWordsByX(words) {
    for i, _ in words {
        for j, _ in words {
            if (j > i && words[j].x < words[i].x) {
                tmp := words[i]
                words[i] := words[j]
                words[j] := tmp
            }
        }
    }
}

NormalizeLineText(line) {
    cleaned := Trim(line)
    cleaned := StrReplace(cleaned, "×", "x")
    cleaned := StrReplace(cleaned, "—", "-")
    cleaned := StrReplace(cleaned, "–", "-")
    cleaned := RegExReplace(cleaned, "\s+", " ")
    return cleaned
}

ParseRivenAttributes(lines, rawText := "") {
    if (Type(lines) = "String") {
        lines := StrSplit(lines, "`n", "`r")
    }

    attributeLines := []
    current := ""

    for line in lines {
        text := NormalizeLineText(line)
        if (text = "") {
            continue
        }

        if (IsLikelyAttributeStart(text)) {
            if (current != "") {
                attributeLines.Push(current)
            }
            current := text
        } else if (current != "") {
            current .= " " . text
        }
    }

    if (current != "") {
        attributeLines.Push(current)
    }

    parsedAttributes := []
    for line in attributeLines {
        parsed := ParseAttributeLine(line)
        if (parsed) {
            parsedAttributes.Push(parsed)
        }
    }

    return {
        count: parsedAttributes.Length,
        attributes: parsedAttributes,
        raw: rawText,
        lines: lines
    }
}

IsLikelyAttributeStart(text) {
    return RegExMatch(text, "^[\+\-xX]\s*\d")
}

ParseAttributeLine(attributeLine) {
    line := NormalizeLineText(attributeLine)
    if (!RegExMatch(line, "^([\+\-xX])\s*([0-9]+(?:\s*[.,]\s*[0-9]+)?)\s*(%?)\s*(.*)$", &match)) {
        return false
    }

    symbol := match[1]
    hasPercent := match[3] = "%"
    value := RegExReplace(match[2], "\s+", "")
    value := StrReplace(value, ",", ".")
    numericValue := CoerceNumber(value, "")
    if (numericValue = "") {
        return false
    }
    numericValue := Round(numericValue, 2)
    rawName := Trim(match[4])
    rawName := RegExReplace(rawName, "[^A-Za-z0-9\s()]+", " ")
    rawName := Trim(RegExReplace(rawName, "\s+", " "))
    rawName := StripLeadingIconNoise(rawName)
    if (rawName = "") {
        return false
    }

    labelMatch := MatchAttributeLabel(rawName)
    mappedLabel := labelMatch.label
    mappedId := labelMatch.attrId
    isMapped := labelMatch.isMapped

    attrId := mappedId
    if (attrId = "") {
        unknownSlug := Slugify(rawName)
        if (unknownSlug = "") {
            unknownSlug := "unknown"
        }
        attrId := "unknown-" . unknownSlug
    }
    polarity := DetermineAttributePolarity(symbol, numericValue, attrId)

    return {
        symbol: symbol,
        value: numericValue,
        raw: rawName,
        label: mappedLabel != "" ? mappedLabel : rawName,
        attrId: attrId,
        polarity: polarity,
        hasPercent: hasPercent,
        matchConfidence: labelMatch.confidence,
        isMapped: isMapped
    }
}

DetermineAttributePolarity(symbol, numericValue := "", attrId := "") {
    if (attrId = "weapon-recoil") {
        if (symbol = "-") {
            return "positive"
        }
        if (symbol = "+") {
            return "negative"
        }
    }

    if (symbol = "-") {
        return "negative"
    }

    numeric := CoerceNumber(numericValue, "")
    if ((symbol = "x" || symbol = "X") && numeric != "" && numeric < 1) {
        ; Multipliers under 1 are negative faction modifiers.
        return "negative"
    }

    return "positive"
}

CoerceNumber(value, defaultValue := 0) {
    if (IsNumber(value)) {
        return value + 0
    }

    text := Trim(value . "")
    if (text = "") {
        return defaultValue
    }

    text := StrReplace(text, ",", ".")
    if (RegExMatch(text, "^-?(?:\d+(?:\.\d+)?|\.\d+)$")) {
        return text + 0
    }

    return defaultValue
}

StripLeadingIconNoise(text) {
    cleaned := Trim(text)
    if (cleaned = "") {
        return ""
    }

    ; The small damage icon sometimes OCRs as a short prefix token:
    ; "f Electricity", "x Cold", "ox Toxin", etc.
    cleaned := RegExReplace(cleaned, "i)^[a-z0-9]{1,3}\s+(Puncture|Impact|Slash|Electricity|Heat|Cold|Toxin)\b", "$1")
    cleaned := RegExReplace(cleaned, "i)^[a-z0-9]{1,3}\s+(Damage\s+to\s+(Corpus|Grineer|Infested))\b", "$1")

    ; Generic fallback: if first token is short non-numeric noise and we still have
    ; at least one real token, drop it.
    tokens := StrSplit(cleaned, " ")
    if (tokens.Length >= 2 && StrLen(tokens[1]) <= 2 && !RegExMatch(tokens[1], "^\d+$")) {
        tokens.RemoveAt(1)
        cleaned := JoinStringArray(tokens, " ")
    }

    return Trim(cleaned)
}

MatchAttributeLabel(text) {
    global ATTRIBUTE_LABELS, ATTRIBUTE_LABEL_TO_ID

    candidate := NormalizeAttributeText(text)
    bestLabel := ""
    bestScore := 0.0

    for label in ATTRIBUTE_LABELS {
        score := ComputeLabelMatchScore(candidate, label)
        if (score > bestScore) {
            bestScore := score
            bestLabel := label
        }
    }

    if (bestLabel != "" && bestScore >= 0.55) {
        return {
            label: bestLabel,
            attrId: ATTRIBUTE_LABEL_TO_ID[bestLabel],
            confidence: Round(bestScore, 3),
            isMapped: true
        }
    }

    return {
        label: text,
        attrId: "",
        confidence: Round(bestScore, 3),
        isMapped: false
    }
}

ComputeLabelMatchScore(normalizedText, label) {
    normalizedLabel := NormalizeAttributeText(label)
    if (normalizedText = normalizedLabel) {
        return 1.0
    }

    if (InStr(normalizedText, normalizedLabel)) {
        return 0.95
    }
    if (InStr(normalizedLabel, normalizedText)) {
        return 0.85
    }

    textTokens := Tokenize(normalizedText)
    labelTokens := Tokenize(normalizedLabel)
    if (labelTokens.Length = 0 || textTokens.Length = 0) {
        return 0.0
    }

    shared := 0
    for token in labelTokens {
        if (ArrayContains(textTokens, token)) {
            shared++
        }
    }

    coverageLabel := shared / labelTokens.Length
    coverageText := shared / textTokens.Length

    score := (coverageLabel * 0.7) + (coverageText * 0.3)
    if (shared > 0 && labelTokens[1] = textTokens[1]) {
        score += 0.08
    }
    return Min(1.0, score)
}

NormalizeAttributeText(text) {
    normalized := " " . StrLower(text) . " "

    ; Common OCR and shorthand repairs.
    normalized := RegExReplace(normalized, "i)\bcrit\b", " critical ")
    normalized := RegExReplace(normalized, "i)\bcritcal\b", " critical ")
    normalized := RegExReplace(normalized, "i)\bchance for slide\b", " chance for slide attack ")
    normalized := RegExReplace(normalized, "i)\bheavy attacks?\b", " heavy attacks ")
    normalized := RegExReplace(normalized, "i)\bmele[e3]\b", " melee ")
    normalized := RegExReplace(normalized, "i)\bmag\b", " magazine ")
    normalized := RegExReplace(normalized, "i)\breloadspd\b", " reload speed ")
    normalized := RegExReplace(normalized, "i)\battk\b", " attack ")
    normalized := RegExReplace(normalized, "i)\bcorpu[s]?\b", " corpus ")
    normalized := RegExReplace(normalized, "i)\bgrinee[r]?\b", " grineer ")
    normalized := RegExReplace(normalized, "i)\binfeste[d]?\b", " infested ")

    normalized := RegExReplace(normalized, "\([^)]*\)", " ")
    normalized := RegExReplace(normalized, "[^a-z0-9]+", " ")
    normalized := Trim(RegExReplace(normalized, "\s+", " "))
    return normalized
}

Tokenize(text) {
    if (text = "") {
        return []
    }

    tokens := []
    for token in StrSplit(text, " ") {
        if (token = "") {
            continue
        }
        if (StrLen(token) = 1 && !RegExMatch(token, "^\d$")) {
            continue
        }
        tokens.Push(token)
    }
    return tokens
}

BuildCandidateFromParsedAttributes(rivenData) {
    candidate := {attributes: []}

    if (!IsObject(rivenData)) {
        return candidate
    }
    if (!rivenData.HasOwnProp("attributes")) {
        return candidate
    }

    for attr in rivenData.attributes {
        attrId := attr.HasOwnProp("attrId") ? attr.attrId : ""
        if (attrId = "") {
            rawName := attr.HasOwnProp("raw") ? attr.raw : "unknown"
            slug := Slugify(rawName)
            attrId := slug = "" ? "unknown" : ("unknown-" . slug)
        }

        if (attr.HasOwnProp("polarity")) {
            polarity := attr.polarity
        } else {
            symbol := attr.HasOwnProp("symbol") ? attr.symbol : "+"
            value := attr.HasOwnProp("value") ? attr.value : ""
            polarity := DetermineAttributePolarity(symbol, value, attrId)
        }
        candidate.attributes.Push({
            attrId: attrId,
            polarity: polarity
        })
    }

    return candidate
}
