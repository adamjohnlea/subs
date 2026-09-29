import Foundation
import Translation

public enum TranslatorError: Error {
    case notInstalled(target: Locale.Language)
}

public protocol Translating: Sendable {
    /// Translates each input string independently, preserving order and count.
    func translate(_ lines: [String],
                   from source: Locale.Language,
                   to target: Locale.Language) async throws -> [String]
}

public struct AppleTranslator: Translating {
    public init() {}

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
