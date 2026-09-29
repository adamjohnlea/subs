import Testing
@testable import subs

@Test func themeAccentIsDistinctFromAccentDim() {
    #expect(Theme.accent != Theme.accentDim)
}
