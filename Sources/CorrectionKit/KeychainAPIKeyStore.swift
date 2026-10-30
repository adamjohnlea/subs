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
public enum KeychainError: Error, Equatable, CustomStringConvertible {
    /// The Security framework returned a status this store does not handle.
    case unexpectedStatus(OSStatus)

    /// A plain-language reason, with the Security framework's message when it has one.
    public var description: String {
        switch self {
        case .unexpectedStatus(let status):
            let message = SecCopyErrorMessageString(status, nil) as String?
            return message.map { "\($0) (status \(status))" } ?? "Keychain status \(status)"
        }
    }
}

/// An `APIKeyStore` backed by a generic-password item in the login keychain.
///
/// The item uses service `com.adamjohnlea.subs` and account `claude-api-key`.
public struct KeychainAPIKeyStore: APIKeyStore {
    private let service: String
    private let account: String

    /// Creates a store that reads and writes the login keychain.
    public init() {
        self.init(service: "com.adamjohnlea.subs", account: "claude-api-key")
    }

    /// Creates a store for a specific keychain item.
    ///
    /// Internal so tests can target a throwaway item and never touch the real key.
    init(service: String, account: String) {
        self.service = service
        self.account = account
    }

    public func claudeKey() throws -> String? {
        var query = itemQuery
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

        var addQuery = itemQuery
        addQuery[kSecValueData as String] = data
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        switch addStatus {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let updateStatus = SecItemUpdate(
                itemQuery as CFDictionary,
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
        let status = SecItemDelete(itemQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private var itemQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
