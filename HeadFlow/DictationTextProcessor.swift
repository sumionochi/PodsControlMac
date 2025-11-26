// DictationTextProcessor.swift
import Foundation

/// Transforms raw speech-recognizer text into something suitable
/// for insertion into a text field:
/// - Applies user-defined DictationCommand replacements.
/// - Maps commands like "new line" → "\n"
/// - Maps "period", "comma", "question mark", etc → punctuation
/// - Cleans up spacing around punctuation.
enum DictationTextProcessor {

    static func process(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        // 1) Apply user-defined commands first (smiley face → 😊, new para → \n\n, etc.)
        let processedForCommands = applyCustomCommands(trimmed)

        // 2) Then run our built-in token logic
        let tokens = tokenize(processedForCommands)
        let outputTokens = mapTokens(tokens)
        return buildString(from: outputTokens)
    }

    // MARK: - Token types

    private enum OutputToken {
        case word(String)
        case punctuation(String)
        case newline
        case tab
    }

    // MARK: - Tokenization

    private static func tokenize(_ text: String) -> [String] {
        text.split(whereSeparator: { $0.isWhitespace }).map { String($0) }
    }

    private static func cleanCommand(_ token: String) -> String {
        token
            .lowercased()
            .trimmingCharacters(in: .punctuationCharacters)
    }

    // MARK: - Map speech tokens → OutputToken

    private static func mapTokens(_ tokens: [String]) -> [OutputToken] {
        var result: [OutputToken] = []
        var i = 0

        while i < tokens.count {
            let token = tokens[i]
            let clean = cleanCommand(token)

            let hasNext = (i + 1 < tokens.count)
            let hasNext2 = (i + 2 < tokens.count)

            let nextClean = hasNext ? cleanCommand(tokens[i + 1]) : nil
            let next2Clean = hasNext2 ? cleanCommand(tokens[i + 2]) : nil

            // ===== MULTI-WORD COMMANDS =====

            // new line / next line / line break
            if (clean == "new" || clean == "next"),
               let nextClean {
                if nextClean == "line" || nextClean == "row" {
                    result.append(.newline)
                    i += 2
                    continue
                } else if nextClean == "paragraph" || nextClean == "para" {
                    result.append(.newline)
                    result.append(.newline)
                    i += 2
                    continue
                }
            }

            // line break / paragraph break
            if clean == "line", let nextClean, nextClean == "break" {
                result.append(.newline)
                i += 2
                continue
            }
            if clean == "paragraph", let nextClean, nextClean == "break" {
                result.append(.newline)
                result.append(.newline)
                i += 2
                continue
            }

            // question mark
            if clean == "question", let nextClean, nextClean == "mark" {
                result.append(.punctuation("?"))
                i += 2
                continue
            }

            // exclamation mark / exclamation point
            if clean == "exclamation", let nextClean,
               (nextClean == "mark" || nextClean == "point") {
                result.append(.punctuation("!"))
                i += 2
                continue
            }

            // tab key
            if clean == "tab", let nextClean, nextClean == "key" {
                result.append(.tab)
                i += 2
                continue
            }

            // dot dot dot → …
            if clean == "dot",
               let nextClean, let next2Clean,
               nextClean == "dot", next2Clean == "dot" {
                result.append(.punctuation("…"))
                i += 3
                continue
            }

            // open / close parenthesis / brackets / braces / angles / quotes
            if clean == "open", let nextClean {
                switch nextClean {
                case "parenthesis", "paren":
                    result.append(.punctuation("("))
                    i += 2
                    continue
                case "bracket", "square", "squarebracket":
                    result.append(.punctuation("["))
                    i += 2
                    continue
                case "brace", "curly", "curlybrace":
                    result.append(.punctuation("{"))
                    i += 2
                    continue
                case "angle", "chevron":
                    result.append(.punctuation("<"))
                    i += 2
                    continue
                case "quote", "quotes", "doublequote":
                    result.append(.punctuation("“"))
                    i += 2
                    continue
                case "singlequote", "singlequotes", "apostrophe":
                    result.append(.punctuation("‘"))
                    i += 2
                    continue
                default:
                    break
                }
            }

            if (clean == "close" || clean == "closing" || clean == "end"),
               let nextClean {
                switch nextClean {
                case "parenthesis", "paren":
                    result.append(.punctuation(")"))
                    i += 2
                    continue
                case "bracket", "square", "squarebracket":
                    result.append(.punctuation("]"))
                    i += 2
                    continue
                case "brace", "curly", "curlybrace":
                    result.append(.punctuation("}"))
                    i += 2
                    continue
                case "angle", "chevron":
                    result.append(.punctuation(">"))
                    i += 2
                    continue
                case "quote", "quotes", "doublequote":
                    result.append(.punctuation("”"))
                    i += 2
                    continue
                case "singlequote", "singlequotes", "apostrophe":
                    result.append(.punctuation("’"))
                    i += 2
                    continue
                default:
                    break
                }
            }

            // currency symbols: dollar sign, euro sign, pound sign, yen sign
            if let nextClean,
               (clean == "dollar" || clean == "euro" || clean == "pound" || clean == "yen"),
               (nextClean == "sign" || nextClean == "symbol") {

                let symbol: String
                switch clean {
                case "dollar": symbol = "$"
                case "euro":   symbol = "€"
                case "pound":  symbol = "£"
                case "yen":    symbol = "¥"
                default:       symbol = ""
                }

                if !symbol.isEmpty {
                    result.append(.punctuation(symbol))
                    i += 2
                    continue
                }
            }

            // percent sign
            if clean == "percent", let nextClean,
               (nextClean == "sign" || nextClean == "symbol") {
                result.append(.punctuation("%"))
                i += 2
                continue
            }

            // at sign
            if clean == "at", let nextClean,
               (nextClean == "sign" || nextClean == "symbol") {
                result.append(.punctuation("@"))
                i += 2
                continue
            }

            // hash / hashtag / number sign
            if (clean == "hash" || clean == "hashtag" || clean == "number" || clean == "pound"),
               let nextClean, (nextClean == "sign" || nextClean == "symbol") {
                result.append(.punctuation("#"))
                i += 2
                continue
            }

            // ===== SINGLE-WORD COMMANDS =====

            switch clean {
            // layout
            case "newline", "enter", "return":
                result.append(.newline)

            case "tab":
                result.append(.tab)

            // core punctuation
            case "period", "dot", "stop", "fullstop", "full-stop":
                result.append(.punctuation("."))

            case "comma":
                result.append(.punctuation(","))

            case "questionmark":
                result.append(.punctuation("?"))

            case "exclamation", "exclamationmark", "exclamationpoint", "bang":
                result.append(.punctuation("!"))

            case "colon":
                result.append(.punctuation(":"))

            case "semicolon", "semi", "semi-colon":
                result.append(.punctuation(";"))

            case "dash", "hyphen":
                result.append(.punctuation("-"))

            case "underscore", "under-score":
                result.append(.punctuation("_"))

            case "slash", "forwardslash", "forward-slash":
                result.append(.punctuation("/"))

            case "backslash", "back-slash":
                result.append(.punctuation("\\"))

            case "ampersand":
                result.append(.punctuation("&"))

            case "asterisk":
                result.append(.punctuation("*"))

            case "plus", "plus-sign":
                result.append(.punctuation("+"))

            case "minus":
                result.append(.punctuation("-"))

            case "equals", "equal", "equal-sign":
                result.append(.punctuation("="))

            case "ellipsis":
                result.append(.punctuation("…"))

            // quotes
            case "quote", "quotes", "doublequote", "doublequotes":
                result.append(.punctuation("\""))

            case "apostrophe", "singlequote", "singlequotes":
                result.append(.punctuation("'"))

            // dashes variants
            case "emdash", "em-dash":
                result.append(.punctuation("—"))

            case "endash", "en-dash":
                result.append(.punctuation("–"))

            // bullet points
            case "bullet", "bulletpoint":
                result.append(.word("•"))

            default:
                // Normal word
                result.append(.word(token))
            }

            i += 1
        }

        return result
    }

    // MARK: - Build final string with nice spacing

    private static func buildString(from tokens: [OutputToken]) -> String {
        var result = ""
        for (index, token) in tokens.enumerated() {
            let next = index + 1 < tokens.count ? tokens[index + 1] : nil

            switch token {
            case .word(let text):
                // Add a space if last char isn’t whitespace/newline and we’re not at start.
                if let last = result.last, !last.isWhitespace, last != "\n" {
                    result.append(" ")
                }
                result.append(text)

            case .punctuation(let mark):
                // Remove trailing spaces before punctuation
                while let last = result.last, last == " " {
                    result.removeLast()
                }
                result.append(mark)

                // If next is a word, add a space after punctuation.
                if let next {
                    if case .word = next {
                        result.append(" ")
                    }
                }

            case .newline:
                // Avoid double-newlines unless they were explicitly requested.
                if !result.hasSuffix("\n") {
                    result.append("\n")
                }

            case .tab:
                result.append("\t")
            }
        }
        return result
    }

    // MARK: - Custom Commands

    /// Applies user-defined voice command replacements BEFORE tokenization
    /// so they participate in the same spacing / punctuation rules.
    private static func applyCustomCommands(_ text: String) -> String {
        var result = text

        // Get custom commands from settings
        let commands = HeadFlowSettings.dictationCustomCommands

        for command in commands {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: command.trigger))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(
                    in: result,
                    options: [],
                    range: range,
                    withTemplate: command.replacement
                )
            }
        }

        return result
    }
}
