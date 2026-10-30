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

@Test func transcriptURLSwapsVideoExtensionForSRT() {
    let video = URL(fileURLWithPath: "/movies/film.mp4")
    #expect(OutputPath.transcriptURL(forVideo: video).path == "/movies/film.srt")
}

@Test func correctionSiblingsSitNextToTranscript() {
    let transcript = URL(fileURLWithPath: "/movies/My Film.srt")
    #expect(OutputPath.originalTranscriptURL(forTranscript: transcript).path == "/movies/My Film.original.srt")
    #expect(OutputPath.correctionsURL(forTranscript: transcript).path == "/movies/My Film.corrections.md")
}
