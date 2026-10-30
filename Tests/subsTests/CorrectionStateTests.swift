import Testing
import Foundation
@testable import subs
@testable import SubtitleKit

@MainActor
@Test func correctionIsOffByDefault() {
    #expect(AppModel().correctionEnabled == false)
    #expect(AppModel().correctionFailure == nil)
}

@Test func correctionFailureExposesTheErrorMessage() {
    let failure = CorrectionFailure(.http(500))
    #expect(failure.message == CorrectorError.http(500).description)
    #expect(failure.guidance == nil)
}

@Test func missingKeyFailureTellsTheUserToSetTheKey() {
    let failure = CorrectionFailure(.noKey)
    #expect(failure.message == CorrectorError.noKey.description)
    #expect(failure.guidance?.contains("subs set-claude-key") == true)
}

@MainActor
@Test func startOverClearsCorrectionOptInAndFailure() {
    let model = AppModel()
    model.correctionEnabled = true
    model.correctionFailure = CorrectionFailure(.truncated)
    model.screen = .transcribing

    model.startOver()

    #expect(model.correctionEnabled == false)
    #expect(model.correctionFailure == nil)
    #expect(model.screen == .input)
}
