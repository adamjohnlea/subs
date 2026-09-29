import Foundation
import Translation

public struct TargetLanguage: Hashable, Sendable {
    public let code: String          // "es"
    public let displayName: String   // "Spanish"
    public var language: Locale.Language { Locale.Language(identifier: code) }
    public init(code: String, displayName: String) {
        self.code = code
        self.displayName = displayName
    }
}

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

public protocol LanguageAvailabilityChecking: Sendable {
    /// Returns only those candidates whose `source -> target` pack is installed.
    func installed(from source: Locale.Language,
                   candidates: [TargetLanguage]) async -> [TargetLanguage]
}

public struct SystemLanguageAvailability: LanguageAvailabilityChecking {
    public init() {}

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
