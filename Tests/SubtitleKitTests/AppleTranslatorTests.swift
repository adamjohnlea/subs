import Foundation
import Testing
import Translation
@testable import SubtitleKit

/// Live test against Apple's on-device Translation framework.
///
/// This exercises the real `AppleTranslator` batch path, which the orchestration tests
/// cannot cover because they inject a fake. It requires an installed en→es language pack.
/// When no pack is installed (as on CI), it returns early and passes, so it never breaks
/// a machine that cannot run the framework while still covering a developer machine that can.
@Test func appleTranslatorBatchPreservesCountAndBlankLines() async throws {
    let english = Locale.Language(identifier: "en")
    let spanish = Locale.Language(identifier: "es")

    let status = await LanguageAvailability().status(from: english, to: spanish)
    guard status == .installed else { return }

    let input = [
        "Hello, world.",
        "",
        "How are you today?",
        "   ",
        "Goodbye."
    ]

    let output = try await AppleTranslator().translate(input, from: english, to: spanish)

    // The contract, not exact wording: translations drift, so assert structure.
    #expect(output.count == input.count)
    #expect(output[1].isEmpty)                                            // blank stays blank
    #expect(output[3] == "   ")                                           // whitespace-only carried through
    #expect(!output[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    #expect(!output[2].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    #expect(!output[4].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
}
