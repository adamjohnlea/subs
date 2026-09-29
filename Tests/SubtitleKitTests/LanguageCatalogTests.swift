import Foundation
import Testing
@testable import SubtitleKit

@Test func catalogHasCommonLanguagesWithTwoLetterCodes() {
    let codes = Set(LanguageCatalog.candidates.map(\.code))
    #expect(codes.contains("es"))
    #expect(codes.contains("fr"))
    #expect(codes.contains("de"))
    for target in LanguageCatalog.candidates {
        #expect(target.code.count == 2)
        #expect(!target.displayName.isEmpty)
    }
}

@Test func candidateCodesAreUnique() {
    let codes = LanguageCatalog.candidates.map(\.code)
    #expect(codes.count == Set(codes).count)
}
