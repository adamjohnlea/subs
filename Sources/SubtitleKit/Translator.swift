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

    /// Translates every non-blank line in a single batch request, leaving blank lines untouched.
    ///
    /// Blank lines are not sent to the translator; they are carried through unchanged so that
    /// line indices and count are preserved. Each request carries its line index as a
    /// `clientIdentifier`, and responses are mapped back by that identifier rather than by
    /// assuming the framework returns them in request order.
    ///
    /// - Throws: `TranslatorError.notInstalled` if the target language pack is missing.
    public func translate(_ lines: [String],
                          from source: Locale.Language,
                          to target: Locale.Language) async throws -> [String] {
        guard !lines.isEmpty else { return [] }

        // Build one request per non-blank line, tagging each with its index so the
        // response can be routed back to the right position.
        var requests: [TranslationSession.Request] = []
        for (index, line) in lines.enumerated()
        where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            requests.append(TranslationSession.Request(sourceText: line, clientIdentifier: String(index)))
        }

        // Start from the originals so blank lines (and any line we did not send) stay put.
        var out = lines
        guard !requests.isEmpty else { return out }

        let session = TranslationSession(installedSource: source, target: target)
        do {
            let responses = try await session.translations(from: requests)
            for response in responses {
                guard let identifier = response.clientIdentifier,
                      let index = Int(identifier),
                      lines.indices.contains(index) else { continue }
                out[index] = response.targetText
            }
            return out
        } catch TranslationError.notInstalled {
            throw TranslatorError.notInstalled(target: target)
        }
    }
}
