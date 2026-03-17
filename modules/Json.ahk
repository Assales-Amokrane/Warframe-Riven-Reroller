#Requires AutoHotkey v2.0

class Json {
    static Parse(text) {
        pos := 1
        value := this.ParseValue(text, &pos)
        this.SkipWhitespace(text, &pos)

        if (pos <= StrLen(text)) {
            throw Error("Unexpected trailing content at position " . pos)
        }

        return value
    }

    static ParseValue(text, &pos) {
        this.SkipWhitespace(text, &pos)
        if (pos > StrLen(text)) {
            throw Error("Unexpected end of JSON input")
        }

        ch := SubStr(text, pos, 1)
        switch ch {
            case "{":
                return this.ParseObject(text, &pos)
            case "[":
                return this.ParseArray(text, &pos)
            case Chr(34):
                return this.ParseString(text, &pos)
            case "-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                return this.ParseNumber(text, &pos)
        }

        if (SubStr(text, pos, 4) = "true") {
            pos += 4
            return true
        }
        if (SubStr(text, pos, 5) = "false") {
            pos += 5
            return false
        }
        if (SubStr(text, pos, 4) = "null") {
            pos += 4
            return ""
        }

        throw Error("Invalid JSON value at position " . pos)
    }

    static ParseObject(text, &pos) {
        obj := {}
        pos++ ; Skip {
        this.SkipWhitespace(text, &pos)

        if (SubStr(text, pos, 1) = "}") {
            pos++
            return obj
        }

        loop {
            this.SkipWhitespace(text, &pos)
            key := this.ParseString(text, &pos)
            this.SkipWhitespace(text, &pos)

            if (SubStr(text, pos, 1) != ":") {
                throw Error("Expected ':' in object at position " . pos)
            }
            pos++

            value := this.ParseValue(text, &pos)
            obj.%key% := value

            this.SkipWhitespace(text, &pos)
            ch := SubStr(text, pos, 1)
            if (ch = "}") {
                pos++
                break
            }
            if (ch != ",") {
                throw Error("Expected ',' or '}' in object at position " . pos)
            }
            pos++
        }

        return obj
    }

    static ParseArray(text, &pos) {
        arr := []
        pos++ ; Skip [
        this.SkipWhitespace(text, &pos)

        if (SubStr(text, pos, 1) = "]") {
            pos++
            return arr
        }

        loop {
            value := this.ParseValue(text, &pos)
            arr.Push(value)

            this.SkipWhitespace(text, &pos)
            ch := SubStr(text, pos, 1)
            if (ch = "]") {
                pos++
                break
            }
            if (ch != ",") {
                throw Error("Expected ',' or ']' in array at position " . pos)
            }
            pos++
        }

        return arr
    }

    static ParseString(text, &pos) {
        if (SubStr(text, pos, 1) != Chr(34)) {
            throw Error("Expected string at position " . pos)
        }
        pos++ ; Skip opening quote.

        out := ""
        textLen := StrLen(text)
        while (pos <= textLen) {
            ch := SubStr(text, pos, 1)
            if (ch = Chr(34)) {
                pos++
                return out
            }

            if (ch = "\") {
                pos++
                if (pos > textLen) {
                    throw Error("Unterminated escape sequence in string")
                }

                esc := SubStr(text, pos, 1)
                switch esc {
                    case Chr(34), "\", "/":
                        out .= esc
                    case "b":
                        out .= Chr(8)
                    case "f":
                        out .= Chr(12)
                    case "n":
                        out .= "`n"
                    case "r":
                        out .= "`r"
                    case "t":
                        out .= "`t"
                    case "u":
                        hex := SubStr(text, pos + 1, 4)
                        if (!RegExMatch(hex, "^[0-9A-Fa-f]{4}$")) {
                            throw Error("Invalid unicode escape at position " . pos)
                        }
                        out .= Chr(Integer("0x" . hex))
                        pos += 4
                    default:
                        throw Error("Unsupported escape character '" . esc . "' at position " . pos)
                }
            } else {
                out .= ch
            }

            pos++
        }

        throw Error("Unterminated string literal")
    }

    static ParseNumber(text, &pos) {
        remainder := SubStr(text, pos)
        if (!RegExMatch(remainder, "^-?(0|[1-9]\d*)(\.\d+)?([eE][\+\-]?\d+)?", &match)) {
            throw Error("Invalid number at position " . pos)
        }

        numberText := match[0]
        pos += StrLen(numberText)
        return numberText + 0
    }

    static SkipWhitespace(text, &pos) {
        textLen := StrLen(text)
        while (pos <= textLen) {
            ch := SubStr(text, pos, 1)
            if (ch != " " && ch != "`t" && ch != "`n" && ch != "`r") {
                break
            }
            pos++
        }
    }
}
