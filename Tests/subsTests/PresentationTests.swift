import Testing
import Foundation
@testable import subs
@testable import SubtitleKit

@Test func stepItemsHasFourEntriesWithExactlyOneActive() {
    let items = stepItems(active: .translate)
    #expect(items.count == 4)
    #expect(items.filter(\.isActive).count == 1)
    #expect(items[2].isActive)
    #expect(items[0].label == "Choose input")
    #expect(items[3].label == "Done")
}

@Test func screenMapsToStep() {
    #expect(AppModel.Screen.input.step == .input)
    #expect(AppModel.Screen.languages.step == .languages)
    #expect(AppModel.Screen.running.step == .translate)
    #expect(AppModel.Screen.done.step == .done)
}

@Test func progressLineComputesPercentAndCount() {
    let p = progressLine(completedUnits: 3, totalUnits: 5)
    #expect(p.percentText == "60%")
    #expect(p.countText == "3 of 5")
    #expect(abs(p.fraction - 0.6) < 0.0001)
}

@Test func progressLineHandlesZeroTotal() {
    let p = progressLine(completedUnits: 0, totalUnits: 0)
    #expect(p.fraction == 0)
    #expect(p.percentText == "0%")
    #expect(p.countText == "0 of 0")
}

private func sampleOutcomes() -> [JobOutcome] {
    let es = TargetLanguage(code: "es", displayName: "Spanish")
    let it = TargetLanguage(code: "it", displayName: "Italian")
    return [
        JobOutcome(input: URL(fileURLWithPath: "/m/a.srt"), target: es,
                   output: URL(fileURLWithPath: "/m/a.es.srt"), errorMessage: nil),
        JobOutcome(input: URL(fileURLWithPath: "/m/a.srt"), target: it,
                   output: nil, errorMessage: "pack not installed"),
    ]
}

@Test func doneRowsSplitSuccessAndFailure() {
    let rows = doneRows(sampleOutcomes())
    #expect(rows.count == 2)
    #expect(rows[0].kind == .success)
    #expect(rows[0].primary == "a.es.srt")
    #expect(rows[0].code == nil)
    #expect(rows[1].kind == .failure)
    #expect(rows[1].primary == "a.srt")
    #expect(rows[1].code == "it")
    #expect(rows[1].reason == "pack not installed")
}

@Test func doneSummaryCountsAndFindsFolder() {
    let s = doneSummary(sampleOutcomes())
    #expect(s.written == 1)
    #expect(s.failed == 1)
    #expect(s.outputFolder == "/m")
}
