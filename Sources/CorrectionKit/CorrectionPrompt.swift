import Foundation
import SubtitleKit

/// Builds the Claude request for correcting a transcript and parses the reply.
///
/// Everything here is pure: no network, no key handling, so it can be tested directly.
public enum CorrectionPrompt {
    /// The model that performs corrections.
    static let model = "claude-opus-5-5"

    /// The instructions that frame the proofreading task.
    public static func system() -> String {
        """
        You are proofreading an automatically generated English transcript of a Blender 3D tutorial. \
        The transcript is a numbered list of words, one per line, written "<index>: <word>".

        Change only clear transcription errors:
        - misheard technical jargon (for example "bullion" for "Boolean")
        - non-words the speech recognizer invented
        - real words that are wrong for the context, such as homophones
        - dropped words that change the meaning, such as a missing "not"

        Leave anything uncertain unchanged. Do not rephrase, restyle, add punctuation, fix grammar, \
        or improve the speaker's wording. If the transcript needs no corrections, return no edits.

        Blender vocabulary you can expect: Voronoi, Boolean, subdivision surface, OptiX denoising, BSDF, \
        IOR, HDRI, bevel, bezier, remesh, geometry nodes, displacement, color ramp, shade smooth, \
        grid fill, solidify, Cycles, depth of field, Eevee, UV unwrap, normal map, principled shader, \
        mirror modifier, array modifier, loop cut, extrude, proportional editing.

        Some words carry recognizer signals. A "(confidence x)" note after a word is the recognizer's \
        confidence in it, and confidence is not a reliable guide to correctness: a confidently wrong \
        word is still wrong. A bracketed line such as [alternative transcriptions of words 3-5: "a" | "b"] \
        lists what the recognizer considered for that whole span of words, not for each word alone. \
        When alternatives are given, prefer choosing among them over inventing words.

        Return edits over the word indices. Each edit replaces the inclusive range start...end with the \
        words in "replacement". An empty replacement deletes the range. To insert a word, replace one \
        word with that word plus the new one. Keep edits small and non-overlapping, and give a short reason for each.
        """
    }

    /// Lists the words one per line, with the recognizer's signals where it supplied any.
    ///
    /// Alternatives belong to a whole recognition segment, so every word in a segment
    /// carries the same list. Each run of consecutive words sharing one non-empty list
    /// gets that list once, in a bracketed line above the run, instead of on every word.
    public static func userMessage(for words: [TranscribedWord]) -> String {
        var lines: [String] = []
        var runStart = 0
        while runStart < words.count {
            let alternatives = words[runStart].alternatives
            var runEnd = runStart
            while runEnd + 1 < words.count, words[runEnd + 1].alternatives == alternatives {
                runEnd += 1
            }
            if !alternatives.isEmpty {
                let span = runStart == runEnd ? "word \(runStart)" : "words \(runStart)-\(runEnd)"
                let quoted = alternatives.map { "\"\($0)\"" }.joined(separator: " | ")
                lines.append("[alternative transcriptions of \(span): \(quoted)]")
            }
            for index in runStart...runEnd {
                var line = "\(index): \(words[index].text)"
                if let confidence = words[index].confidence {
                    line += "  (confidence \(String(format: "%.2f", confidence)))"
                }
                lines.append(line)
            }
            runStart = runEnd + 1
        }
        return lines.joined(separator: "\n")
    }

    /// The JSON schema the model's answer must follow.
    ///
    /// Structured outputs require every object to forbid extra properties and to list
    /// all of its properties as required, and they reject size constraints.
    static var editsSchema: [String: Any] {
        [
            "type": "object",
            "properties": [
                "edits": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "start": ["type": "integer"],
                            "end": ["type": "integer"],
                            "replacement": ["type": "array", "items": ["type": "string"]],
                            "reason": ["type": "string"],
                        ],
                        "required": ["start", "end", "replacement", "reason"],
                        "additionalProperties": false,
                    ] as [String: Any],
                ] as [String: Any],
            ],
            "required": ["edits"],
            "additionalProperties": false,
        ]
    }

    /// The JSON body of a Messages API request asking for corrections to `words`.
    public static func requestBody(for words: [TranscribedWord]) -> Data {
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 16000,
            "thinking": ["type": "adaptive"],
            "output_config": [
                "effort": "high",
                "format": ["type": "json_schema", "schema": editsSchema] as [String: Any],
            ] as [String: Any],
            "system": system(),
            "messages": [["role": "user", "content": userMessage(for: words)]],
        ]
        do {
            return try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        } catch {
            // The body is built only from strings, numbers, arrays and dictionaries, which always serialize.
            preconditionFailure("Request body is not valid JSON: \(error)")
        }
    }

    /// Extracts the edits from a Messages API response.
    ///
    /// - Parameters:
    ///   - responseData: The raw response body.
    ///   - httpStatus: The HTTP status code of the response.
    /// - Returns: The edits Claude proposed, empty when it found nothing to fix.
    /// - Throws: `CorrectorError.http` for a non-200 status, `.refused` when Claude declined,
    ///   `.truncated` when it ran out of tokens, and `.malformedResponse` for anything unreadable.
    public static func parseEdits(from responseData: Data, httpStatus: Int) throws -> [WordEdit] {
        guard httpStatus == 200 else { throw CorrectorError.http(httpStatus) }

        let envelope: Envelope
        do {
            envelope = try JSONDecoder().decode(Envelope.self, from: responseData)
        } catch {
            throw CorrectorError.malformedResponse
        }

        let text = envelope.content.first { $0.type == "text" }?.text
        switch envelope.stopReason {
        case "refusal":
            throw CorrectorError.refused(text ?? "No explanation was given.")
        case "max_tokens":
            throw CorrectorError.truncated
        default:
            break
        }

        guard let text else { throw CorrectorError.malformedResponse }
        do {
            let payload = try JSONDecoder().decode(EditsPayload.self, from: Data(text.utf8))
            return payload.edits.map {
                WordEdit(start: $0.start, end: $0.end, replacement: $0.replacement, reason: $0.reason)
            }
        } catch {
            throw CorrectorError.malformedResponse
        }
    }

    private struct Envelope: Decodable {
        let stopReason: String?
        let content: [Block]

        struct Block: Decodable {
            let type: String
            let text: String?
        }

        enum CodingKeys: String, CodingKey {
            case stopReason = "stop_reason"
            case content
        }
    }

    private struct EditsPayload: Decodable {
        let edits: [Edit]

        struct Edit: Decodable {
            let start: Int
            let end: Int
            let replacement: [String]
            let reason: String
        }
    }
}
