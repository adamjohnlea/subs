import Foundation
import Translation

/// A language that subtitles can be translated into.
public struct TargetLanguage: Hashable, Sendable {
    /// The language code, e.g. "es".
    public let code: String
    /// The human-readable name, e.g. "Spanish".
    public let displayName: String
    /// The language as a `Locale.Language` value.
    public var language: Locale.Language { Locale.Language(identifier: code) }
    /// Creates a target language from its code and display name.
    public init(code: String, displayName: String) {
        self.code = code
        self.displayName = displayName
    }
}

/// The languages the app offers as translation targets.
public enum LanguageCatalog {
    /// Common targets offered before filtering by what is installed.
    public static let candidates: [TargetLanguage] = [
        .init(code: "es", displayName: "Spanish"),
        .init(code: "fr", displayName: "French"),
        .init(code: "de", displayName: "German"),
        .init(code: "it", displayName: "Italian"),
        .init(code: "pt", displayName: "Portuguese"),
        .init(code: "nl", displayName: "Dutch"),
        .init(code: "ru", displayName: "Russian"),
        .init(code: "ja", displayName: "Japanese"),
        .init(code: "ko", displayName: "Korean"),
        .init(code: "zh", displayName: "Chinese"),
        .init(code: "ar", displayName: "Arabic"),
        .init(code: "hi", displayName: "Hindi"),
        .init(code: "pl", displayName: "Polish"),
        .init(code: "tr", displayName: "Turkish"),
        .init(code: "uk", displayName: "Ukrainian"),
    ]
}

/// Reports which target languages can be translated to on this device.
public protocol LanguageAvailabilityChecking: Sendable {
    /// Returns only those candidates whose `source -> target` pack is installed.
    ///
    /// - Parameters:
    ///   - source: The language being translated from.
    ///   - candidates: The target languages to check.
    func installed(from source: Locale.Language,
                   candidates: [TargetLanguage]) async -> [TargetLanguage]
}

/// Checks language availability using Apple's Translation framework.
public struct SystemLanguageAvailability: LanguageAvailabilityChecking {
    /// Creates an availability checker.
    public init() {}

    /// Returns the candidates whose `source -> target` pack is installed on this device.
    public func installed(from source: Locale.Language,
                          candidates: [TargetLanguage]) async -> [TargetLanguage] {
        let availability = LanguageAvailability()
        var result: [TargetLanguage] = []
        for candidate in candidates {
            let status = await availability.status(from: source, to: candidate.language)
            if status == .installed { result.append(candidate) }
        }
        return result
    }
}
