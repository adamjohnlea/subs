import Foundation
import Testing
import SubtitleKit
@testable import CorrectionKit

@Test func userMessageNumbersWordsAndIncludesSignals() {
    let words = [TranscribedWord(text: "a", start: 0, end: 1),
                 TranscribedWord(text: "bullion", start: 1, end: 2, confidence: 0.98, alternatives: ["Boolean"])]
    let msg = CorrectionPrompt.userMessage(for: words)
    #expect(msg.contains("0: a"))
    #expect(msg.contains("1: bullion"))
    #expect(msg.contains("Boolean"))          // alternative surfaced
}

@Test func promptOmitsSignalsWhenAbsent() {          // Review Focus: headless signals absent
    let words = [TranscribedWord(text: "a", start: 0, end: 1),
                 TranscribedWord(text: "b", start: 1, end: 2)]
    let msg = CorrectionPrompt.userMessage(for: words)
    #expect(!msg.lowercased().contains("confidence"))
    #expect(!msg.lowercased().contains("alternative"))
}

@Test func segmentAlternativesArePresentedOncePerSpan() {
    let shared = ["mesh Boolean modifier"]
    let words = [TranscribedWord(text: "plain", start: 0, end: 1),
                 TranscribedWord(text: "mesh", start: 1, end: 2, alternatives: shared),
                 TranscribedWord(text: "bullion", start: 2, end: 3, alternatives: shared),
                 TranscribedWord(text: "modifier", start: 3, end: 4, alternatives: shared),
                 TranscribedWord(text: "next", start: 4, end: 5, alternatives: ["other"])]
    let msg = CorrectionPrompt.userMessage(for: words)
    #expect(msg.components(separatedBy: "mesh Boolean modifier").count - 1 == 1)   // once, not three times
    #expect(msg.contains("words 1-3"))
    #expect(msg.contains("other"))
    #expect(msg.contains("1: mesh"))
    #expect(msg.contains("3: modifier"))
}

@Test func requestBodyPinsModelAndSchema() throws {
    let body = try #require(try JSONSerialization.jsonObject(with: CorrectionPrompt.requestBody(for: [TranscribedWord(text: "a", start: 0, end: 1)])) as? [String: Any])
    #expect(body["model"] as? String == "claude-opus-5-5")
    let output = try #require(body["output_config"] as? [String: Any])
    let format = try #require(output["format"] as? [String: Any])
    #expect(format["type"] as? String == "json_schema")
}

@Test func requestBodyCarriesThinkingEffortAndStrictSchema() throws {
    let body = try #require(try JSONSerialization.jsonObject(with: CorrectionPrompt.requestBody(for: [TranscribedWord(text: "a", start: 0, end: 1)])) as? [String: Any])
    #expect(body["max_tokens"] as? Int == 16000)
    #expect((body["thinking"] as? [String: Any])?["type"] as? String == "adaptive")
    let output = try #require(body["output_config"] as? [String: Any])
    #expect(output["effort"] as? String == "high")
    let schema = try #require((output["format"] as? [String: Any])?["schema"] as? [String: Any])
    #expect(schema["additionalProperties"] as? Bool == false)
    #expect(schema["required"] as? [String] == ["edits"])
    let items = try #require(((schema["properties"] as? [String: Any])?["edits"] as? [String: Any])?["items"] as? [String: Any])
    #expect(items["additionalProperties"] as? Bool == false)
    #expect(Set(items["required"] as? [String] ?? []) == ["start", "end", "replacement", "reason"])
}

@Test func parseExtractsEditsFromStructuredText() throws {
    let json = #"{"stop_reason":"end_turn","content":[{"type":"text","text":"{\"edits\":[{\"start\":1,\"end\":1,\"replacement\":[\"Boolean\"],\"reason\":\"3D term\"}]}"}]}"#
    let edits = try CorrectionPrompt.parseEdits(from: Data(json.utf8), httpStatus: 200)
    #expect(edits == [WordEdit(start: 1, end: 1, replacement: ["Boolean"], reason: "3D term")])
}

@Test func parseSkipsLeadingThinkingBlock() throws {
    let json = #"{"stop_reason":"end_turn","content":[{"type":"thinking","thinking":"hm"},{"type":"text","text":"{\"edits\":[]}"}]}"#
    #expect(try CorrectionPrompt.parseEdits(from: Data(json.utf8), httpStatus: 200).isEmpty)
}

@Test func parseRejectsRefusal() {                   // Review Focus: refusal
    let json = #"{"stop_reason":"refusal","content":[]}"#
    #expect(throws: CorrectorError.self) { try CorrectionPrompt.parseEdits(from: Data(json.utf8), httpStatus: 200) }
}

@Test func parseRejectsTruncation() {                // Review Focus: max_tokens
    let json = #"{"stop_reason":"max_tokens","content":[{"type":"text","text":"{\"edits\":["}]}"#
    #expect(throws: CorrectorError.truncated) { try CorrectionPrompt.parseEdits(from: Data(json.utf8), httpStatus: 200) }
}

@Test func parseRejectsHTTPError() {                 // Review Focus: bad key / API error
    #expect(throws: CorrectorError.http(401)) { try CorrectionPrompt.parseEdits(from: Data("{}".utf8), httpStatus: 401) }
}

@Test func parseRejectsMalformedBodies() {
    #expect(throws: CorrectorError.malformedResponse) { try CorrectionPrompt.parseEdits(from: Data("not json".utf8), httpStatus: 200) }
    let noText = #"{"stop_reason":"end_turn","content":[]}"#
    #expect(throws: CorrectorError.malformedResponse) { try CorrectionPrompt.parseEdits(from: Data(noText.utf8), httpStatus: 200) }
    let badEdits = #"{"stop_reason":"end_turn","content":[{"type":"text","text":"{\"nope\":1}"}]}"#
    #expect(throws: CorrectorError.malformedResponse) { try CorrectionPrompt.parseEdits(from: Data(badEdits.utf8), httpStatus: 200) }
}
