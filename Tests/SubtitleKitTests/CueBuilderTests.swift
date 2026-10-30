import Testing
@testable import SubtitleKit

private func w(_ text: String, _ start: Double, _ end: Double) -> TranscribedWord {
    TranscribedWord(text: text, start: start, end: end)
}

@Test func groupsContiguousSpeechIntoOneCue() {
    let cues = CueBuilder.cues(from: [w("Hello", 0, 0.4), w("there", 0.4, 0.9)])
    #expect(cues.count == 1)
    #expect(cues[0].index == 1)
    #expect(cues[0].start == "00:00:00,000")
    #expect(cues[0].textLines == ["Hello there"])
    // Stretched to the 1s minimum on-screen duration.
    #expect(cues[0].end == "00:00:01,000")
}

@Test func breaksCueOnLongPause() {
    let cues = CueBuilder.cues(from: [w("One", 0, 0.5), w("two", 2.0, 2.5)]) // 1.5s gap > 0.8s
    #expect(cues.count == 2)
    #expect(cues[0].textLines == ["One"])
    #expect(cues[1].textLines == ["two"])
}

@Test func stretchedCueNeverOverlapsNext() {
    // The first cue's 1s minimum stretch would reach into the next cue, so it
    // is capped to leave a 0.1s gap before the next cue starts at 1.0s.
    let cues = CueBuilder.cues(from: [w("Hi", 0, 0.2), w("again", 1.0, 1.4)])
    #expect(cues.count == 2)
    #expect(cues[0].end == "00:00:00,900")
}

@Test func emptyWordsProduceNoCues() {
    #expect(CueBuilder.cues(from: []).isEmpty)
}

@Test func transcribedWordCarriesOptionalSignals() {
    let bare = TranscribedWord(text: "Boolean", start: 0, end: 1)
    #expect(bare.confidence == nil)
    #expect(bare.alternatives.isEmpty)
    let rich = TranscribedWord(text: "bullion", start: 0, end: 1, confidence: 0.98, alternatives: ["Boolean"])
    #expect(rich.confidence == 0.98)
    #expect(rich.alternatives == ["Boolean"])
}

@Test func cueBuildingIgnoresSignals() {
    // Same words, one bare and one with signals, group into identical cues.
    let a = CueBuilder.cues(from: [TranscribedWord(text: "Hi.", start: 0, end: 0.5)])
    let b = CueBuilder.cues(from: [TranscribedWord(text: "Hi.", start: 0, end: 0.5, confidence: 0.4, alternatives: ["High"])])
    #expect(a == b)
}
