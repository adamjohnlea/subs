import Testing
@testable import SubtitleKit

@Test func wrapKeepsShortTextOnOneLine() {
    #expect(SubtitleLayout.wrap("Hello world") == ["Hello world"])
    #expect(SubtitleLayout.fits("Hello world"))
}

@Test func wrapSplitsLongTextIntoTwoBalancedLines() {
    let text = "This is a fairly long subtitle line that will not fit on one row at all"
    let lines = SubtitleLayout.wrap(text)
    #expect(lines.count == 2)
    #expect(lines.allSatisfy { $0.count <= SubtitleLayout.maxLineLength })
    #expect(lines.joined(separator: " ") == text)   // no words lost
}
