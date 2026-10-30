import Foundation

/// Transcribes one video into an English `.srt` next to it, reusing an existing
/// `.srt` rather than overwriting it. The written (or reused) URL is returned,
/// ready for the translation pipeline.
///
/// When a `TranscriptCorrecting` is supplied, a freshly produced transcript is
/// corrected before it is written, and the pre-correction transcript and a
/// changelog are kept beside it. A reused transcript is never corrected.
public struct TranscriptionJob {
    private let transcriber: Transcribing
    private let corrector: TranscriptCorrecting?
    private let writer: SRTWriter
    private let fileManager: FileManager

    /// - Parameters:
    ///   - transcriber: Produces the word-level transcript.
    ///   - corrector: When non-nil, corrects freshly produced transcripts. Never applied to a reused `.srt`.
    ///   - writer: Serializes cues to SRT text.
    ///   - fileManager: Used for the reuse check.
    public init(transcriber: Transcribing,
                corrector: TranscriptCorrecting? = nil,
                writer: SRTWriter = SRTWriter(),
                fileManager: FileManager = .default) {
        self.transcriber = transcriber
        self.corrector = corrector
        self.writer = writer
        self.fileManager = fileManager
    }

    /// Writes (or reuses) the English `.srt` for `video`.
    ///
    /// With a corrector and a fresh transcript this also writes `film.original.srt`
    /// (the uncorrected transcript) and `film.corrections.md` (the changelog).
    ///
    /// - Returns: The `.srt` URL next to the video.
    /// - Throws: `TranscriberError.noSpeechFound` when no speech is recognized
    ///   (no file is written), any error from the transcriber, or any error from
    ///   the corrector (no file is written, so the caller can retry uncorrected).
    public func run(video: URL,
                    progress: @Sendable @escaping (TranscriptionStage) -> Void) async throws -> URL {
        let output = OutputPath.transcriptURL(forVideo: video)
        if fileManager.fileExists(atPath: output.path) {
            return output   // reuse a hand-corrected or prior transcript
        }
        let words = try await transcriber.transcribe(video: video, progress: progress)
        guard let corrector else {
            let cues = CueBuilder.cues(from: words)
            guard !cues.isEmpty else { throw TranscriberError.noSpeechFound }
            try write(cues, to: output)
            return output
        }
        let edits = try await corrector.edits(for: words)
        let (corrected, changes) = CorrectionApply.apply(edits, to: words)
        let cues = CueBuilder.cues(from: corrected)
        guard !cues.isEmpty else { throw TranscriberError.noSpeechFound }
        try write(CueBuilder.cues(from: words), to: OutputPath.originalTranscriptURL(forTranscript: output))
        try CorrectionApply.changelogMarkdown(from: changes)
            .write(to: OutputPath.correctionsURL(forTranscript: output), atomically: true, encoding: .utf8)
        try write(cues, to: output)
        return output
    }

    private func write(_ cues: [Cue], to url: URL) throws {
        try writer.write(SubtitleDocument(cues: cues)).write(to: url, atomically: true, encoding: .utf8)
    }
}
