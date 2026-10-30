import Foundation
import Testing
@testable import CorrectionKit
import SubtitleKit

/// Fake proves `APIKeyStore` consumers can be tested without the Keychain.
private final class FakeKeyStore: APIKeyStore, @unchecked Sendable {
    var stored: String?
    func claudeKey() throws -> String? { stored }
    func setClaudeKey(_ key: String) throws { stored = key }
    func deleteClaudeKey() throws { stored = nil }
}

@Test func fakeKeyStoreRoundTrips() throws {
    let store = FakeKeyStore()
    #expect(try store.claudeKey() == nil)
    try store.setClaudeKey("sk-ant-test")
    #expect(try store.claudeKey() == "sk-ant-test")
    try store.deleteClaudeKey()
    #expect(try store.claudeKey() == nil)
}

/// Live round-trip against the real login keychain; returns early where the
/// environment has no keychain access (CI).
@Test func keychainStoreRoundTripsWhenAvailable() throws {
    // A unique throwaway service so this test can never touch the user's real key.
    let store = KeychainAPIKeyStore(
        service: "com.adamjohnlea.subs.tests.\(UUID().uuidString)",
        account: "claude-api-key"
    )
    defer {
        do { try store.deleteClaudeKey() } catch { Issue.record("keychain cleanup failed: \(error)") }
    }
    let probe = "sk-ant-roundtrip-\(UUID().uuidString)"
    do {
        try store.setClaudeKey(probe)
        #expect(try store.claudeKey() == probe)
    } catch { return }   // no keychain access in this environment: skip, don't fail
    try store.deleteClaudeKey()
    #expect(try store.claudeKey() == nil)
}

private struct ThrowingKeyStore: APIKeyStore {
    let error: any Error
    func claudeKey() throws -> String? { throw error }
    func setClaudeKey(_ key: String) throws { throw error }
    func deleteClaudeKey() throws { throw error }
}

@Test func unreadableKeychainIsNotReportedAsAMissingKey() async {
    // errSecInteractionNotAllowed (-25308): the keychain is locked.
    let corrector = ClaudeCorrector(keyStore: ThrowingKeyStore(error: KeychainError.unexpectedStatus(-25308)))
    do {
        _ = try await corrector.edits(for: [])
        Issue.record("expected a CorrectorError")
    } catch let error as CorrectorError {
        guard case .keychain(let reason) = error else {
            Issue.record("expected .keychain, got \(error)")
            return
        }
        #expect(reason.contains("-25308"))
    } catch {
        Issue.record("expected a CorrectorError, got \(error)")
    }
}

@Test func missingKeyIsStillNoKey() async {
    let corrector = ClaudeCorrector(keyStore: FakeKeyStore())
    do {
        _ = try await corrector.edits(for: [])
        Issue.record("expected a CorrectorError")
    } catch {
        #expect(error as? CorrectorError == .noKey)
    }
}
