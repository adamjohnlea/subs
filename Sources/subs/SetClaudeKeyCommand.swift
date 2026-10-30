import CorrectionKit
import Foundation
import SwiftTUI

/// `subs set-claude-key`: saves the Claude API key to the Keychain, then exits
/// without starting the TUI.
///
/// The key is read from a no-echo prompt, never from an argument, so it cannot
/// land in shell history or the process list.
struct SetClaudeKeyCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-claude-key",
        abstract: "Save your Claude API key to the Keychain for transcript correction."
    )

    /// Why no key was saved.
    enum KeyEntryError: Error, CustomStringConvertible {
        case promptUnavailable
        case emptyKey

        var description: String {
            switch self {
            case .promptUnavailable:
                return "Couldn't read a key from the terminal. Run this command in an interactive terminal."
            case .emptyKey:
                return "No key was entered, so nothing was saved."
            }
        }
    }

    func run() throws {
        // `getpass` turns echo off while the user types. It reads from the
        // terminal, so a missing terminal is an error, never a silent skip.
        guard let entry = getpass("Claude API key (input is hidden): ") else {
            throw KeyEntryError.promptUnavailable
        }
        let key = String(cString: entry).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw KeyEntryError.emptyKey }
        try KeychainAPIKeyStore().setClaudeKey(key)
        print("Saved your Claude API key to the Keychain.")
    }
}
