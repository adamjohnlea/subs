import Foundation

/// A correction to a run of transcribed words.
///
/// Replaces the inclusive word range `start...end` (indices into the transcript's
/// word array) with `replacement`. An empty `replacement` deletes the range, and
/// replacing a one-word range with two words inserts a word, such as a dropped "not".
public struct WordEdit: Equatable, Sendable {
    /// Index of the first word replaced.
    public let start: Int
    /// Index of the last word replaced, inclusive.
    public let end: Int
    /// The words that take the place of the range.
    public let replacement: [String]
    /// A short explanation of why the edit was made.
    public let reason: String

    /// Creates an edit that replaces the words `start...end` with `replacement`.
    public init(start: Int, end: Int, replacement: [String], reason: String) {
        self.start = start
        self.end = end
        self.replacement = replacement
        self.reason = reason
    }
}

/// Errors raised while asking a language model to correct a transcript.
public enum CorrectorError: Error, Equatable, CustomStringConvertible {
    /// No Claude API key is stored.
    case noKey
    /// The model declined to answer, with its explanation when it gave one.
    case refused(String)
    /// The model ran out of room before finishing its answer.
    case truncated
    /// The service answered with this non-success HTTP status code.
    case http(Int)
    /// The response could not be understood.
    case malformedResponse
    /// The request could not be sent or the response could not be received.
    case transport(String)

    /// A plain-language message suitable for showing to the user.
    public var description: String {
        switch self {
        case .noKey:
            return "No Claude API key is saved. Add one to correct transcripts."
        case .refused(let explanation):
            return "Claude declined to correct this transcript: \(explanation)"
        case .truncated:
            return "Claude's answer was cut off before it finished, so no corrections were applied."
        case .http(let status):
            return "The Claude service returned an error (HTTP \(status))."
        case .malformedResponse:
            return "The Claude service sent a response that couldn't be understood."
        case .transport(let message):
            return "Couldn't reach the Claude service: \(message)"
        }
    }
}

/// Proposes corrections to a transcript's words.
///
/// The concrete, network-backed implementation lives in the `CorrectionKit`
/// module; this protocol keeps `SubtitleKit` pure Foundation.
public protocol TranscriptCorrecting: Sendable {
    /// Returns the edits that fix clear transcription errors in `words`.
    ///
    /// - Parameter words: The transcript, in order. Edit indices refer to positions in this array.
    /// - Returns: The proposed edits, empty when the transcript needs none.
    /// - Throws: A `CorrectorError` when corrections could not be obtained.
    func edits(for words: [TranscribedWord]) async throws -> [WordEdit]
}
