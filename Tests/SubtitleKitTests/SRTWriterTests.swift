import Testing
@testable import SubtitleKit

@Test func writesCanonicalBlock() {
    let doc = SubtitleDocument(cues: [
        Cue(index: 1, start: "00:00:01,000", end: "00:00:04,000", textLines: ["Hello", "world"])
    ])
    let expected = "1\n00:00:01,000 --> 00:00:04,000\nHello\nworld\n"
    #expect(SRTWriter().write(doc) == expected)
}

@Test func writesBlankLineBetweenCues() {
    let doc = SubtitleDocument(cues: [
        Cue(index: 1, start: "00:00:01,000", end: "00:00:02,000", textLines: ["A"]),
        Cue(index: 2, start: "00:00:03,000", end: "00:00:04,000", textLines: ["B"]),
    ])
    let expected = "1\n00:00:01,000 --> 00:00:02,000\nA\n\n2\n00:00:03,000 --> 00:00:04,000\nB\n"
    #expect(SRTWriter().write(doc) == expected)
}

@Test func roundTripPreservesIndicesAndTimestamps() throws {
    let source = """
    1
    00:00:01,000 --> 00:00:04,000
    Line one
    Line two

    2
    00:00:05,500 --> 00:00:07,000
    Second
    """
    let doc = try SRTParser().parse(source)
    let reparsed = try SRTParser().parse(SRTWriter().write(doc))
    #expect(reparsed == doc)
}
