import Foundation

/// Serializes a `SubtitleDocument` back to `.srt` text.
public struct SRTWriter {
    /// Creates a writer.
    public init() {}

    /// Serializes a document to `.srt` text, with one blank line between cues and a trailing newline.
    ///
    /// - Parameter document: The document to serialize.
    /// - Returns: The `.srt` text.
    public func write(_ document: SubtitleDocument) -> String {
        let blocks = document.cues.map { cue -> String in
            var lines = ["\(cue.index)", "\(cue.start) --> \(cue.end)"]
            lines.append(contentsOf: cue.textLines)
            return lines.joined(separator: "\n")
        }
        // Each block ends with a newline; blocks are separated by one blank line.
        return blocks.joined(separator: "\n\n") + "\n"
    }
}
