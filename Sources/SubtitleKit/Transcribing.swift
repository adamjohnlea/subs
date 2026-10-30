import Foundation

/// A step of transcription, for progress reporting.
public enum TranscriptionStage: Equatable, Sendable {
    /// The English speech model is downloading, `fraction` (0...1) done.
    case downloadingModel(fraction: Double)
    /// The audio is being transcribed, `fraction` (0...1) of the way through.
    case transcribing(fraction: Double)
}

/// Errors raised while transcribing a video.
public enum TranscriberError: Error, Equatable, CustomStringConvertible {
    /// On-device transcription is not available on this Mac.
    case unavailable
    /// The file has no audio track to transcribe.
    case noAudioTrack
    /// The audio contained no recognizable speech.
    case noSpeechFound
    /// The speech-model reservation cap is full and English is not reserved.
    case modelReservationFull(held: [String])
    /// The audio could not be extracted from the file for transcription.
    case audioExtractionFailed

    /// A plain-language message suitable for showing to the user.
    public var description: String {
        switch self {
        case .unavailable:
            return "Transcription isn't available on this Mac."
        case .noAudioTrack:
            return "This file has no audio to transcribe."
        case .noSpeechFound:
            return "No speech found in this video."
        case .audioExtractionFailed:
            return "Couldn't extract audio from this video."
        case .modelReservationFull(let held):
            return "This Mac can keep speech models for only a few languages, and they're all in use: "
                + "\(held.joined(separator: ", ")). Free one in System Settings to transcribe."
        }
    }
}

/// Transcribes a video's speech into timed words.
///
/// The concrete, Apple-backed implementation lives in the `TranscriptionKit`
/// module; this protocol keeps `SubtitleKit` free of the Speech and AVFoundation
/// frameworks so the subtitle-parsing core stays pure Foundation.
public protocol Transcribing: Sendable {
    func transcribe(video: URL,
                    progress: @Sendable @escaping (TranscriptionStage) -> Void) async throws -> [TranscribedWord]
}
