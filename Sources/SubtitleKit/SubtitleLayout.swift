import Foundation

/// Line wrapping for subtitles: at most two lines, each at most `maxLineLength`
/// characters, split at the space that balances the two lines best. v1 handles
/// spaced (English) text only.
enum SubtitleLayout {
    /// The longest a single subtitle line may be, in characters (Netflix guideline).
    static let maxLineLength = 42

    /// Wraps text onto one line if it fits, otherwise two lines split at the
    /// space that makes the longer line as short as possible. May still exceed
    /// `maxLineLength` if the text cannot fit two lines; check with `fits(_:)`.
    static func wrap(_ text: String) -> [String] {
        guard text.count > maxLineLength else { return [text] }
        let words = text.split(separator: " ").map(String.init)
        guard words.count > 1 else { return [text] }
        func longest(_ index: Int) -> Int {
            max(words[..<index].joined(separator: " ").count,
                words[index...].joined(separator: " ").count)
        }
        let best = (1..<words.count).min { longest($0) < longest($1) } ?? 1
        return [words[..<best].joined(separator: " "), words[best...].joined(separator: " ")]
    }

    /// Whether text wraps into at most two lines of at most `maxLineLength`.
    static func fits(_ text: String) -> Bool {
        let lines = wrap(text)
        return lines.count <= 2 && lines.allSatisfy { $0.count <= maxLineLength }
    }
}
