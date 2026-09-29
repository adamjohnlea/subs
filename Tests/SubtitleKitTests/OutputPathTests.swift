import Foundation
import Testing
@testable import SubtitleKit

@Test func insertsLanguageCodeBeforeExtension() {
    let input = URL(fileURLWithPath: "/movies/film.srt")
    let out = OutputPath.translatedURL(for: input, languageCode: "es")
    #expect(out.path == "/movies/film.es.srt")
}

@Test func handlesDottedBasenames() {
    let input = URL(fileURLWithPath: "/movies/S01.E02.srt")
    let out = OutputPath.translatedURL(for: input, languageCode: "fr")
    #expect(out.path == "/movies/S01.E02.fr.srt")
}
