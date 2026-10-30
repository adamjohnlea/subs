import Foundation
import Security

/// Stores and retrieves the user's Claude API key.
///
/// Consumers depend on this protocol rather than the Keychain so they can be
/// tested with an in-memory fake.
public protocol APIKeyStore: Sendable {
    /// Returns the stored Claude API key, or `nil` when none has been saved.
    func claudeKey() throws -> String?

    /// Saves the Claude API key, replacing any existing one.
    func setClaudeKey(_ key: String) throws

    /// Removes the stored Claude API key. Succeeds when none is stored.
    func deleteClaudeKey() throws
}

/// An error from a Keychain operation.
public enum KeychainError: Error, Equatable {
    /// The Security framework returned a status this store does not handle.
    case unexpectedStatus(OSStatus)
}

/// An `APIKeyStore` backed by a generic-password item in the login keychain.
///
/// The item uses service `com.adamjohnlea.subs` and account `claude-api-key`.
public struct KeychainAPIKeyStore: APIKeyStore {
    private static let service = "com.adamjohnlea.subs"
    private static let account = "claude-api-key"

    /// Creates a store that reads and writes the login keychain.
    public init() {}

    public func claudeKey() throws -> String? {
        var query = Self.itemQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let key = String(data: data, encoding: .utf8) else {
                throw KeychainError.unexpectedStatus(errSecDecode)
            }
            return key
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public func setClaudeKey(_ key: String) throws {
        let data = Data(key.utf8)

        var addQuery = Self.itemQuery
        addQuery[kSecValueData as String] = data
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        switch addStatus {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let updateStatus = SecItemUpdate(
                Self.itemQuery as CFDictionary,
                [kSecValueData as String: data] as CFDictionary
            )
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        default:
            throw KeychainError.unexpectedStatus(addStatus)
        }
    }

    public func deleteClaudeKey() throws {
        let status = SecItemDelete(Self.itemQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private static var itemQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
