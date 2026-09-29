import Foundation

public struct SRTWriter {
    public init() {}

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
