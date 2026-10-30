import Foundation
import Testing
import Speech
import SubtitleKit
@testable import TranscriptionKit

/// Generates a short spoken-audio clip with `/usr/bin/say`.
private func makeSpokenClip() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".aiff")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
    process.arguments = ["-o", url.path, "Hello world this is a transcription test."]
    try process.run()
    process.waitUntilExit()
    return url
}

@Test func appleTranscriberReturnsTimedWords() async throws {
    guard SpeechTranscriber.isAvailable,
          let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US")) else { return }
    let installed = await SpeechTranscriber.installedLocales.map { $0.identifier(.bcp47) }
    guard installed.contains(locale.identifier(.bcp47)) else { return }

    let clip = try makeSpokenClip()
    defer { try? FileManager.default.removeItem(at: clip) }

    let words = try await AppleTranscriber().transcribe(video: clip) { _ in }

    #expect(!words.isEmpty)
    #expect(words.allSatisfy { $0.end >= $0.start })
    #expect(words.contains { $0.text.lowercased().contains("hello") })
}

/// Live check that transcription returns words and reports whether the recognizer's signals populate.
///
/// Set `SUBS_LIVE_CLIP` to the path of a short spoken audio or video file to run it. When the variable is
/// unset, the file is missing, or the speech framework is unavailable, it returns early and passes, so
/// machines that cannot run it (as on CI) stay green.
@Test func liveTranscriptionReturnsWordsAndReportsSignals() async throws {
    guard SpeechTranscriber.isAvailable,
          let path = ProcessInfo.processInfo.environment["SUBS_LIVE_CLIP"],
          FileManager.default.fileExists(atPath: path) else { return }
    let words = try await AppleTranscriber().transcribe(video: URL(fileURLWithPath: path)) { _ in }
    #expect(!words.isEmpty)
    // Informational, not an assertion: records whether the headless path populates signals.
    let withConfidence = words.filter { $0.confidence != nil }.count
    let withAlternatives = words.filter { !$0.alternatives.isEmpty }.count
    FileHandle.standardError.write(Data("signals: \(withConfidence)/\(words.count) confidence, \(withAlternatives)/\(words.count) alternatives\n".utf8))
}
