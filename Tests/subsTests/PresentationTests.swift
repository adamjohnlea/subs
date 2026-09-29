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
