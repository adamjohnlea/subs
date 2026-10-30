import Testing
import CorrectionKit
import Foundation
@testable import subs
@testable import SubtitleKit

@MainActor
@Test func correctionIsOffByDefault() {
    #expect(AppModel().correctionEnabled == false)
    #expect(AppModel().correctionFailure == nil)
}

@Test func correctionFailureExposesTheErrorMessage() {
    let failure = CorrectionFailure(.http(500))
    #expect(failure.message == CorrectorError.http(500).description)
    #expect(failure.guidance == nil)
}

@Test func missingKeyFailureTellsTheUserToSetTheKey() {
    let failure = CorrectionFailure(.noKey)
    #expect(failure.message == CorrectorError.noKey.description)
    #expect(failure.guidance?.contains("subs set-claude-key") == true)
}

@MainActor
@Test func startOverClearsCorrectionOptInAndFailure() {
    let model = AppModel()
    model.correctionEnabled = true
    model.correctionFailure = CorrectionFailure(.truncated)
    model.screen = .transcribing

    model.startOver()

    #expect(model.correctionEnabled == false)
    #expect(model.correctionFailure == nil)
    #expect(model.screen == .input)
}

private struct LockedKeyStore: APIKeyStore {
    func claudeKey() throws -> String? { throw KeychainError.unexpectedStatus(-25308) }
    func setClaudeKey(_ key: String) throws {}
    func deleteClaudeKey() throws {}
}

@Test func keychainReadFailureLandsInTheFailureCardNotTheGenericError() async {
    let corrector = ClaudeCorrector(keyStore: LockedKeyStore())
    do {
        _ = try await corrector.edits(for: [])
        Issue.record("expected a failure")
    } catch {
        let failure = correctionFailure(for: error)
        #expect(failure != nil)
        #expect(failure?.message.contains("Keychain") == true)
        #expect(failure?.message.contains("-25308") == true)
        // Re-entering the key is wrong advice for a locked or denied keychain.
        #expect(failure?.guidance == nil)
    }
}

@Test func nonCorrectorErrorsTakeTheGenericPath() {
    struct Other: Error {}
    #expect(correctionFailure(for: Other()) == nil)
}
