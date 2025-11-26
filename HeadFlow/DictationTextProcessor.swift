// DictationTextProcessor.swift
import Foundation

/// Transforms raw speech-recognizer text into something suitable
/// for insertion into a text field:
/// - Maps commands like "new line" → "\n"
/// - Maps "period", "comma", "question mark", etc → punctuation
/// - Cleans up spacing around punctuation.
enum DictationTextProcessor {

    static func process(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let tokens = tokenize(trimmed)
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

            // Look-ahead for 2-word commands
            let hasNext = (i + 1 < tokens.count)
            let nextClean = hasNext ? cleanCommand(tokens[i + 1]) : nil

            // Multi-word commands first
            if clean == "new", let nextClean {
                if nextClean == "line" {
                    result.append(.newline)
                    i += 2
                    continue
                } else if nextClean == "paragraph" {
                    result.append(.newline)
                    result.append(.newline)
                    i += 2
                    continue
                }
            }

            if clean == "question", let nextClean, nextClean == "mark" {
                result.append(.punctuation("?"))
                i += 2
                continue
            }

            if clean == "exclamation", let nextClean,
               (nextClean == "mark" || nextClean == "point") {
                result.append(.punctuation("!"))
                i += 2
                continue
            }

            if clean == "tab", let nextClean, nextClean == "key" {
                result.append(.tab)
                i += 2
                continue
            }

            // Single-word commands
            switch clean {
            case "newline":
                result.append(.newline)
            case "period", "fullstop", "full-stop":
                result.append(.punctuation("."))
            case "comma":
                result.append(.punctuation(","))
            case "questionmark":
                result.append(.punctuation("?"))
            case "exclamation", "exclamationmark":
                result.append(.punctuation("!"))
            case "tab":
                result.append(.tab)
            default:
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
                    switch next {
                    case .word:
                        result.append(" ")
                    default:
                        break
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
}
