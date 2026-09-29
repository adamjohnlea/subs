import Foundation
import Translation

/// Errors raised by `AppleTranslator`.
public enum TranslatorError: Error {
    /// The translation pack for the target language is not installed.
    case notInstalled(target: Locale.Language)
}

/// Translates lines of text between languages.
public protocol Translating: Sendable {
    /// Translates each input string independently, preserving order and count.
    func translate(_ lines: [String],
                   from source: Locale.Language,
                   to target: Locale.Language) async throws -> [String]
}

/// A `Translating` implementation backed by Apple's on-device Translation framework.
public struct AppleTranslator: Translating {
    /// Creates a translator.
    public init() {}

    /// Translates each line on-device, leaving blank lines untouched.
    ///
    /// - Throws: `TranslatorError.notInstalled` if the target language pack is missing.
    public func translate(_ lines: [String],
                          from source: Locale.Language,
                          to target: Locale.Language) async throws -> [String] {
        guard !lines.isEmpty else { return [] }
        let session = TranslationSession(installedSource: source, target: target)
        do {
            var out: [String] = []
            out.reserveCapacity(lines.count)
            for line in lines {
                // Preserve blank lines untouched; only translate real text.
                if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    out.append(line)
                } else {
                    let response = try await session.translate(line)
                    out.append(response.targetText)
                }
            }
            return out
        } catch TranslationError.notInstalled {
            throw TranslatorError.notInstalled(target: target)
        }
    }
}
