import Foundation

public enum SRTParseError: Error, Equatable {
    case empty
    case missingIndex(block: Int)
    case malformedTimestamp(block: Int)
}

public struct SRTParser {
    public init() {}

    public func parse(_ text: String) throws -> SubtitleDocument {
        // Normalize line endings and strip a leading BOM.
        var normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        normalized = normalized.replacingOccurrences(of: "\r", with: "\n")
        if normalized.first == "\u{FEFF}" { normalized.removeFirst() }

        // Blocks are separated by one or more blank lines.
        let rawBlocks = normalized
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\n")) }
            .filter { !$0.isEmpty }

        if rawBlocks.isEmpty { throw SRTParseError.empty }

        var cues: [Cue] = []
        for (offset, block) in rawBlocks.enumerated() {
            let lines = block.components(separatedBy: "\n")
            guard let index = Int(lines[0].trimmingCharacters(in: .whitespaces)) else {
                throw SRTParseError.missingIndex(block: offset + 1)
            }
            guard lines.count >= 2 else {
                throw SRTParseError.malformedTimestamp(block: offset + 1)
            }
            let (start, end) = try parseTimestamp(lines[1], block: offset + 1)
            let textLines = Array(lines.dropFirst(2))
            cues.append(Cue(index: index, start: start, end: end, textLines: textLines))
        }
        return SubtitleDocument(cues: cues)
    }

    private func parseTimestamp(_ line: String, block: Int) throws -> (String, String) {
        let parts = line.components(separatedBy: " --> ")
        guard parts.count == 2 else { throw SRTParseError.malformedTimestamp(block: block) }
        let start = parts[0].trimmingCharacters(in: .whitespaces)
        let end = parts[1].trimmingCharacters(in: .whitespaces)
        let pattern = #"^\d{2}:\d{2}:\d{2},\d{3}$"#
        guard start.range(of: pattern, options: .regularExpression) != nil,
              end.range(of: pattern, options: .regularExpression) != nil else {
            throw SRTParseError.malformedTimestamp(block: block)
        }
        return (start, end)
    }
}
