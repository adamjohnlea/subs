import Foundation
import Observation
import SubtitleKit

/// The whole app is a five-screen state machine. `AppModel` owns the screen
/// the user is on and every field the screens read and write, so the screen
/// views stay thin and share one source of truth.
///
/// It is a `@MainActor @Observable final class`: SwiftTUI tracks reads made in
/// a view `body` and invalidates exactly the views that read a property that
/// changed. `@MainActor` makes it implicitly `Sendable`, which SwiftTUI's
/// environment storage requires.
@MainActor
@Observable
final class AppModel {
    /// The screens the app moves through, in order.
    enum Screen: Equatable {
        case input
        case transcribing
        case languages
        case running
        case done
    }

    /// The screen currently on display.
    var screen: Screen = .input

    /// The path the user typed on the input screen (a file or a directory).
    var inputPath: String = ""

    /// The video to transcribe, set when the input is a video rather than a subtitle file.
    var videoURL: URL?

    /// The current transcription stage, or `nil` before it starts.
    var transcriptionStage: TranscriptionStage?

    /// Whether this run began from a video (so the Transcribe step is shown).
    var isVideoFlow: Bool = false

    /// The `.srt` files discovered under `inputPath`.
    var discoveredFiles: [URL] = []

    /// Target languages whose translation packs are installed and offerable.
    var availableTargets: [TargetLanguage] = []

    /// The targets the user has selected to translate into.
    var selectedTargets: Set<TargetLanguage> = []

    /// Progress of the running job, or `nil` before it starts.
    var progress: JobProgress?

    /// A human-readable line for each completed unit (file → language), newest
    /// last. View-only state for the run screen's activity list.
    var progressLog: [String] = []

    /// The per-file, per-language results once the job finishes.
    var outcomes: [JobOutcome] = []

    /// A message to surface to the user when something goes wrong.
    var errorMessage: String?

    /// Whether the user has opted in to Claude transcript correction for the
    /// next video. Off by default; the transcript is sent to the Claude API
    /// only when this is on.
    var correctionEnabled: Bool = false

    /// Set when Claude correction failed on the Transcribe screen. While set,
    /// that screen shows the failure and offers Proceed uncorrected or Back
    /// instead of moving on.
    var correctionFailure: CorrectionFailure?

    /// Clears all input, run, and video state and returns to the Choose-input
    /// screen, so the next run starts fresh. Used by "Translate more" on the
    /// done screen; a leftover path or video flow must not carry into a new run.
    func startOver() {
        inputPath = ""
        videoURL = nil
        transcriptionStage = nil
        isVideoFlow = false
        discoveredFiles = []
        availableTargets = []
        selectedTargets = []
        progress = nil
        progressLog = []
        outcomes = []
        errorMessage = nil
        correctionEnabled = false
        correctionFailure = nil
        screen = .input
    }
}

/// A Claude correction failure as shown on the Transcribe screen: the error
/// message, plus how to fix it when the cause is a missing API key.
struct CorrectionFailure: Equatable {
    /// The plain-language reason correction failed.
    let message: String

    /// What to do about it, or `nil` when there is no specific remedy.
    let guidance: String?

    /// Describes `error` for display.
    init(_ error: CorrectorError) {
        message = error.description
        guidance = error == .noKey
            ? "Run `subs set-claude-key` in a terminal to save your key, then try again."
            : nil
    }
}
