import Foundation

/// A single subtitle entry. Index and timestamps are preserved verbatim from
/// the source file; only `textLines` is ever translated.
public struct Cue: Equatable, Sendable {
    /// The cue's sequence number, exactly as it appears in the source file.
    public let index: Int
    /// The start timestamp, kept verbatim from the source file.
    public let start: String   // e.g. "00:00:01,000"
    /// The end timestamp, kept verbatim from the source file.
    public let end: String     // e.g. "00:00:04,000"
    /// The cue's text, one element per line; the only part that is translated.
    public var textLines: [String]

    /// Creates a cue from its index, timestamps, and text lines.
    public init(index: Int, start: String, end: String, textLines: [String]) {
        self.index = index
        self.start = start
        self.end = end
        self.textLines = textLines
    }
}

/// A parsed `.srt` document: an ordered list of cues.
public struct SubtitleDocument: Equatable, Sendable {
    /// The document's cues, in file order.
    public var cues: [Cue]
    /// Creates a document from an ordered list of cues.
    public init(cues: [Cue]) { self.cues = cues }
}
