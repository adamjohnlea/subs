import Foundation
import Testing
@testable import CorrectionKit

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
    defer { try? store.deleteClaudeKey() }
    let probe = "sk-ant-roundtrip-\(UUID().uuidString)"
    do {
        try store.setClaudeKey(probe)
        #expect(try store.claudeKey() == probe)
    } catch { return }   // no keychain access in this environment: skip, don't fail
    try store.deleteClaudeKey()
    #expect(try store.claudeKey() == nil)
}
