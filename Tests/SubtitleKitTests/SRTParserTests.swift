import Testing
@testable import SubtitleKit

private let single = """
1
00:00:01,000 --> 00:00:04,000
Hello world
"""

private let multi = """
1
00:00:01,000 --> 00:00:04,000
Line one
Line two

2
00:00:05,500 --> 00:00:07,000
Second cue
"""

@Test func parsesSingleCue() throws {
    let doc = try SRTParser().parse(single)
    #expect(doc.cues.count == 1)
    #expect(doc.cues[0].index == 1)
    #expect(doc.cues[0].start == "00:00:01,000")
    #expect(doc.cues[0].end == "00:00:04,000")
    #expect(doc.cues[0].textLines == ["Hello world"])
}

@Test func parsesMultipleCuesAndMultilineText() throws {
    let doc = try SRTParser().parse(multi)
    #expect(doc.cues.count == 2)
    #expect(doc.cues[0].textLines == ["Line one", "Line two"])
    #expect(doc.cues[1].index == 2)
    #expect(doc.cues[1].textLines == ["Second cue"])
}

@Test func toleratesCRLFAndBOMAndTrailingBlankLines() throws {
    let text = "\u{FEFF}1\r\n00:00:01,000 --> 00:00:04,000\r\nHi\r\n\r\n"
    let doc = try SRTParser().parse(text)
    #expect(doc.cues.count == 1)
    #expect(doc.cues[0].textLines == ["Hi"])
}

@Test func throwsOnMalformedTimestamp() {
    let bad = "1\nnot-a-timestamp\nHi"
    #expect(throws: SRTParseError.self) { try SRTParser().parse(bad) }
}
