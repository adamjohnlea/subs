import Foundation

/// A step of transcription, for progress reporting.
public enum TranscriptionStage: Equatable, Sendable {
    /// The English speech model is downloading, `fraction` (0...1) done.
    case downloadingModel(fraction: Double)
    /// The audio is being transcribed, `fraction` (0...1) of the way through.
    case transcribing(fraction: Double)
}

/// Errors raised while transcribing a video.
public enum TranscriberError: Error, Equatable {
    /// On-device transcription is not available on this Mac.
    case unavailable
    /// The file has no audio track to transcribe.
    case noAudioTrack
    /// The audio contained no recognizable speech.
    case noSpeechFound
    /// The speech-model reservation cap is full and English is not reserved.
    case modelReservationFull(held: [String])
}

/// Transcribes a video's speech into timed words.
public protocol Transcribing: Sendable {
    func transcribe(video: URL,
                    progress: @Sendable @escaping (TranscriptionStage) -> Void) async throws -> [TranscribedWord]
}

/// Real implementation is completed in Task 5. This stub lets dependents build;
/// it is never exercised (callers inject a fake in tests, and the app uses the
/// Task 5 body).
public struct AppleTranscriber: Transcribing {
    public init() {}
    public func transcribe(video: URL,
                           progress: @Sendable @escaping (TranscriptionStage) -> Void) async throws -> [TranscribedWord] {
        throw TranscriberError.unavailable
    }
}
