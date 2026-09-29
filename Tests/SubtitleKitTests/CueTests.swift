import Testing
@testable import SubtitleKit

@Test func cueEquality() {
    let a = Cue(index: 1, start: "00:00:01,000", end: "00:00:04,000", textLines: ["Hello"])
    let b = Cue(index: 1, start: "00:00:01,000", end: "00:00:04,000", textLines: ["Hello"])
    #expect(a == b)
}
