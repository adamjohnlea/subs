import Testing
@testable import SubtitleKit

private let base = [TranscribedWord(text: "a", start: 0, end: 1),
                    TranscribedWord(text: "bullion", start: 1, end: 2),
                    TranscribedWord(text: "c", start: 2, end: 3)]

@Test func applySubstitutesAndPreservesTiming() {
    let (words, changes) = CorrectionApply.apply([WordEdit(start: 1, end: 1, replacement: ["Boolean"], reason: "3D term")], to: base)
    #expect(words.map(\.text) == ["a", "Boolean", "c"])
    #expect(words[1].start == 1 && words[1].end == 2)   // inherits the replaced word's span
    #expect(changes == [ChangelogEntry(original: "bullion", corrected: "Boolean", reason: "3D term")])
}

@Test func applyInsertsADroppedWord() {
    // "a" -> "a not": a 1-word span replaced by 2 words, timing split across the span.
    let (words, _) = CorrectionApply.apply([WordEdit(start: 0, end: 0, replacement: ["a", "not"], reason: "dropped negation")], to: base)
    #expect(words.map(\.text) == ["a", "not", "bullion", "c"])
    #expect(words[0].start == 0 && words[1].end == 1)
}

@Test func applyDeletesWords() {
    let (words, _) = CorrectionApply.apply([WordEdit(start: 1, end: 1, replacement: [], reason: "stutter")], to: base)
    #expect(words.map(\.text) == ["a", "c"])
}

@Test func applyIgnoresOutOfRangeAndOverlappingEdits() {   // Review Focus: bad indices
    let edits = [WordEdit(start: 5, end: 9, replacement: ["x"], reason: "oob"),
                 WordEdit(start: 2, end: 1, replacement: ["x"], reason: "inverted"),
                 WordEdit(start: 0, end: 1, replacement: ["A", "B"], reason: "ok"),
                 WordEdit(start: 1, end: 2, replacement: ["overlap"], reason: "overlaps the previous")]
    let (words, changes) = CorrectionApply.apply(edits, to: base)
    #expect(words.map(\.text) == ["A", "B", "c"])   // only the valid, non-overlapping edit applied
    #expect(changes.count == 1)
}

@Test func changelogMarkdownListsEachChange() {
    let md = CorrectionApply.changelogMarkdown(from: [ChangelogEntry(original: "bullion", corrected: "Boolean", reason: "3D term")])
    #expect(md.contains("bullion"))
    #expect(md.contains("Boolean"))
    #expect(md.contains("3D term"))
}
