import Foundation

public enum SRTParseError: Error, Equatable {
    case empty
    case missingIndex(block: Int)
    case malformedTimestamp(block: Int)
}

public struct SRTParser: Sendable {
    public init() {}

    public func parse(_ text: String) throws -> SubtitleDocument {
        // Normalize line endings and strip a leading BOM.
        var normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        normalized = normalized.replacingOccurrences(of: "\r", with: "\n")
        if normalized.first == "\u{FEFF}" { normalized.removeFirst() }

        // Split into lines and group into blocks separated by lines that are empty after trimming.
        let allLines = normalized.components(separatedBy: "\n")
        var blocks: [[String]] = []
        var currentBlock: [String] = []

        for line in allLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                // Separator line (empty after trimming)
                if !currentBlock.isEmpty {
                    blocks.append(currentBlock)
                    currentBlock = []
                }
            } else {
                // Non-separator line; keep byte-for-byte as-is
                currentBlock.append(line)
            }
        }

        // Don't forget the last block
        if !currentBlock.isEmpty {
            blocks.append(currentBlock)
        }

        if blocks.isEmpty { throw SRTParseError.empty }

        var cues: [Cue] = []
        for (offset, block) in blocks.enumerated() {
            let trimmedFirstLine = block[0].trimmingCharacters(in: .whitespaces)
            guard let index = Int(trimmedFirstLine) else {
                throw SRTParseError.missingIndex(block: offset + 1)
            }
            guard block.count >= 2 else {
                throw SRTParseError.malformedTimestamp(block: offset + 1)
            }
            let (start, end) = try parseTimestamp(block[1], block: offset + 1)
            let textLines = Array(block.dropFirst(2))
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
