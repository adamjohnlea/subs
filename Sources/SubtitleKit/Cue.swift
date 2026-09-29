import Foundation

/// A single subtitle entry. Index and timestamps are preserved verbatim from
/// the source file; only `textLines` is ever translated.
public struct Cue: Equatable, Sendable {
    public let index: Int
    public let start: String   // e.g. "00:00:01,000"
    public let end: String     // e.g. "00:00:04,000"
    public var textLines: [String]

    public init(index: Int, start: String, end: String, textLines: [String]) {
        self.index = index
        self.start = start
        self.end = end
        self.textLines = textLines
    }
}

/// A parsed `.srt` document: an ordered list of cues.
public struct SubtitleDocument: Equatable, Sendable {
    public var cues: [Cue]
    public init(cues: [Cue]) { self.cues = cues }
}
