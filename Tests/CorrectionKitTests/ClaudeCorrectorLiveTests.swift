import Foundation
import Testing
import SubtitleKit
@testable import CorrectionKit

/// Live test against the real Claude API.
///
/// Like the Apple translator test, it returns early and passes when the machine cannot run it:
/// here, when no API key is stored in the Keychain (as on CI).
@Test func liveCorrectionFixesAKnownSlip() async throws {
    let store = KeychainAPIKeyStore()
    guard try store.claudeKey() != nil else { return }   // no key: skip
    let words = [TranscribedWord(text: "mesh", start: 0, end: 1),
                 TranscribedWord(text: "bullion", start: 1, end: 2, confidence: 0.98, alternatives: ["Boolean"]),
                 TranscribedWord(text: "modifier", start: 2, end: 3)]
    let edits = try await ClaudeCorrector().edits(for: words)
    #expect(edits.contains { $0.replacement.contains("Boolean") })
}
