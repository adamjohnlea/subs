import Foundation
import Testing
@testable import SubtitleKit

private struct FakeTranscriber: Transcribing {
    let words: [TranscribedWord]
    func transcribe(video: URL, progress: @Sendable @escaping (TranscriptionStage) -> Void) async throws -> [TranscribedWord] {
        progress(.transcribing(fraction: 1))
        return words
    }
}

private struct ThrowingTranscriber: Transcribing {
    let error: TranscriberError
    func transcribe(video: URL, progress: @Sendable @escaping (TranscriptionStage) -> Void) async throws -> [TranscribedWord] {
        throw error
    }
}

private func makeTempDir() throws -> URL {
    let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

@Test func writesEnglishSRTNextToVideoAndRoundTrips() async throws {
    let dir = try makeTempDir()
    let video = dir.appendingPathComponent("film.mp4")
    try Data().write(to: video)
    let words = [TranscribedWord(text: "Hello", start: 0, end: 0.5),
                 TranscribedWord(text: "world.", start: 0.5, end: 1.2)]
    let job = TranscriptionJob(transcriber: FakeTranscriber(words: words))

    let out = try await job.run(video: video) { _ in }

    #expect(out.lastPathComponent == "film.srt")
    // Valid SRT: it parses back cleanly into cues (the "valid SRT" guarantee).
    let doc = try SRTParser().parse(String(contentsOf: out, encoding: .utf8))
    #expect(doc.cues.count == 1)
    #expect(doc.cues[0].textLines == ["Hello world."])
}

@Test func reusesExistingSRTInsteadOfOverwriting() async throws {
    let dir = try makeTempDir()
    let video = dir.appendingPathComponent("film.mp4")
    try Data().write(to: video)
    let existing = dir.appendingPathComponent("film.srt")
    let handCorrected = "1\n00:00:01,000 --> 00:00:02,000\nHand corrected\n"
    try handCorrected.write(to: existing, atomically: true, encoding: .utf8)

    let job = TranscriptionJob(transcriber: FakeTranscriber(words: [TranscribedWord(text: "New", start: 0, end: 1)]))
    let out = try await job.run(video: video) { _ in }

    #expect(out == existing)
    #expect(try String(contentsOf: out, encoding: .utf8) == handCorrected)   // untouched
}

@Test func noSpeechThrowsAndWritesNoFile() async throws {
    let dir = try makeTempDir()
    let video = dir.appendingPathComponent("silent.mp4")
    try Data().write(to: video)
    let job = TranscriptionJob(transcriber: FakeTranscriber(words: []))

    await #expect(throws: TranscriberError.noSpeechFound) {
        _ = try await job.run(video: video) { _ in }
    }
    #expect(!FileManager.default.fileExists(atPath: dir.appendingPathComponent("silent.srt").path))
}

@Test func noAudioTrackErrorPropagates() async throws {
    let dir = try makeTempDir()
    let video = dir.appendingPathComponent("noaudio.mp4")
    try Data().write(to: video)
    let job = TranscriptionJob(transcriber: ThrowingTranscriber(error: .noAudioTrack))

    await #expect(throws: TranscriberError.noAudioTrack) {
        _ = try await job.run(video: video) { _ in }
    }
}

@Test func transcriptURLReplacesExtensionWithSRT() {
    let video = URL(fileURLWithPath: "/movies/My Film.mov")
    #expect(OutputPath.transcriptURL(forVideo: video).lastPathComponent == "My Film.srt")
}
