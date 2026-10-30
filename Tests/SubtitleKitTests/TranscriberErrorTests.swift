import Testing
@testable import SubtitleKit

@Test func transcriberErrorsHaveUserFacingMessages() {
    #expect(String(describing: TranscriberError.unavailable) == "Transcription isn't available on this Mac.")
    #expect(String(describing: TranscriberError.noAudioTrack) == "This file has no audio to transcribe.")
    #expect(String(describing: TranscriberError.noSpeechFound) == "No speech found in this video.")
    #expect(String(describing: TranscriberError.audioExtractionFailed) == "Couldn't extract audio from this video.")

    let full = "\(TranscriberError.modelReservationFull(held: ["en-US", "es-ES"]))"
    #expect(full == "This Mac can keep speech models for only a few languages, and they're all in use: en-US, es-ES. Free one in System Settings to transcribe.")
    #expect(full.contains("en-US"))
    #expect(full.contains("es-ES"))
}
