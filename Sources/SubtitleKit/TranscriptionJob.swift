import Foundation

/// Transcribes one video into an English `.srt` next to it, reusing an existing
/// `.srt` rather than overwriting it. The written (or reused) URL is returned,
/// ready for the translation pipeline.
public struct TranscriptionJob {
    private let transcriber: Transcribing
    private let writer: SRTWriter
    private let fileManager: FileManager

    public init(transcriber: Transcribing,
                writer: SRTWriter = SRTWriter(),
                fileManager: FileManager = .default) {
        self.transcriber = transcriber
        self.writer = writer
        self.fileManager = fileManager
    }

    /// Writes (or reuses) the English `.srt` for `video`.
    ///
    /// - Returns: The `.srt` URL next to the video.
    /// - Throws: `TranscriberError.noSpeechFound` when no speech is recognized
    ///   (no file is written), or any error from the transcriber.
    public func run(video: URL,
                    progress: @Sendable @escaping (TranscriptionStage) -> Void) async throws -> URL {
        let output = OutputPath.transcriptURL(forVideo: video)
        if fileManager.fileExists(atPath: output.path) {
            return output   // reuse a hand-corrected or prior transcript
        }
        let words = try await transcriber.transcribe(video: video, progress: progress)
        let cues = CueBuilder.cues(from: words)
        guard !cues.isEmpty else { throw TranscriberError.noSpeechFound }
        let document = SubtitleDocument(cues: cues)
        try writer.write(document).write(to: output, atomically: true, encoding: .utf8)
        return output
    }
}
