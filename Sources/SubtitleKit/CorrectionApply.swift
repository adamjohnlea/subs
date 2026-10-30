import Foundation

/// One correction that was applied to a transcript, for the user-facing changelog.
public struct ChangelogEntry: Equatable, Sendable {
    /// The words that were replaced, joined with spaces.
    public let original: String
    /// The words that took their place, joined with spaces, or empty when the words were deleted.
    public let corrected: String
    /// Why the correction was made.
    public let reason: String

    /// Creates a changelog entry.
    public init(original: String, corrected: String, reason: String) {
        self.original = original
        self.corrected = corrected
        self.reason = reason
    }
}

/// Applies proposed word edits to a transcript and renders a changelog of what changed.
public enum CorrectionApply {
    /// Applies `edits` to `words`, skipping any edit that cannot be applied safely.
    ///
    /// Edits are processed in ascending order of `start`. An edit is dropped when its
    /// range is outside `words`, is inverted (`start > end`), or overlaps a span that an
    /// earlier edit already replaced. Each replaced span passes its time range on to the
    /// replacement words, split evenly. Replacement words carry no confidence or
    /// alternatives, and untouched words pass through unchanged and in order. An empty
    /// `replacement` deletes the span.
    ///
    /// - Parameters:
    ///   - edits: The proposed edits, in any order.
    ///   - words: The transcript the edit indices refer to.
    /// - Returns: The corrected words and one changelog entry per applied edit.
    public static func apply(
        _ edits: [WordEdit],
        to words: [TranscribedWord]
    ) -> (words: [TranscribedWord], changes: [ChangelogEntry]) {
        let ordered = edits.enumerated()
            .sorted { lhs, rhs in
                lhs.element.start != rhs.element.start
                    ? lhs.element.start < rhs.element.start
                    : lhs.offset < rhs.offset
            }
            .map(\.element)

        var corrected: [TranscribedWord] = []
        var changes: [ChangelogEntry] = []
        var nextUntouched = 0   // first word index not yet copied or replaced

        for edit in ordered {
            guard edit.start >= nextUntouched, edit.start <= edit.end, edit.end < words.count else {
                continue
            }
            corrected.append(contentsOf: words[nextUntouched..<edit.start])
            corrected.append(contentsOf: replacementWords(
                for: edit.replacement,
                spanning: words[edit.start].start,
                to: words[edit.end].end
            ))
            changes.append(ChangelogEntry(
                original: words[edit.start...edit.end].map(\.text).joined(separator: " "),
                corrected: edit.replacement.joined(separator: " "),
                reason: edit.reason
            ))
            nextUntouched = edit.end + 1
        }
        corrected.append(contentsOf: words[nextUntouched...])
        return (corrected, changes)
    }

    /// Renders `changes` as a Markdown list, one line per change.
    ///
    /// - Parameter changes: The applied corrections.
    /// - Returns: Markdown text, or an empty string when there are no changes.
    public static func changelogMarkdown(from changes: [ChangelogEntry]) -> String {
        changes.map { change in
            let corrected = change.corrected.isEmpty ? "(deleted)" : "\"\(change.corrected)\""
            return "- \"\(change.original)\" -> \(corrected): \(change.reason)"
        }
        .joined(separator: "\n")
    }

    /// Builds timed words for `texts`, splitting `start...end` evenly between them.
    private static func replacementWords(
        for texts: [String],
        spanning start: Double,
        to end: Double
    ) -> [TranscribedWord] {
        let slice = (end - start) / Double(max(texts.count, 1))
        return texts.enumerated().map { index, text in
            TranscribedWord(
                text: text,
                start: start + slice * Double(index),
                // The last word ends exactly at the span's end, free of rounding drift.
                end: index == texts.count - 1 ? end : start + slice * Double(index + 1)
            )
        }
    }
}
