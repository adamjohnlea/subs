import Foundation
import CorrectionKit
import SubtitleKit
import SwiftTUI
import TranscriptionKit

/// The screen shown for a video input: it transcribes the video into an English
/// `.srt`, then advances to language selection with that file as the input.
struct TranscribeScreen: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            CompactHeader(step: .transcribe, includeTranscribe: true)
            if let failure = model.correctionFailure {
                failureContent(failure)
            } else {
                progressContent
            }
        }
        .task { await run() }
    }

    private var progressContent: some View {
        VStack(alignment: .leading, spacing: 1) {
            VStack(alignment: .leading, spacing: 1) {
                switch model.transcriptionStage {
                case .downloadingModel(let fraction):
                    stageRow("Preparing English speech model…", fraction: fraction)
                case .transcribing(let fraction):
                    stageRow("Transcribing audio…", fraction: fraction)
                case nil:
                    HStack(spacing: 1) {
                        Spinner()
                        Text(" Starting…").foregroundStyle(.secondary)
                    }
                }
            }
            .card("Transcribe")
            HintFooter(hints: [("^C", "cancel")])
        }
    }

    /// The Claude correction failure: the reason, how to fix it when known, and
    /// the two ways forward. The buttons and their keys call the same
    /// functions.
    private func failureContent(_ failure: CorrectionFailure) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            VStack(alignment: .leading, spacing: 1) {
                Text("✗ \(failure.message)").foregroundStyle(.danger)
                if let guidance = failure.guidance {
                    Text(guidance).foregroundStyle(.secondary)
                }
                Text("You can continue with the uncorrected transcript, or go back.")
                    .foregroundStyle(.secondary)
            }
            .card("Claude correction failed")
            Button("Proceed uncorrected") { proceedUncorrected() }
                .foregroundStyle(Theme.accent)
            Button("Back") { goBack() }
                .foregroundStyle(.secondary)
            HintFooter(hints: [("p", "proceed uncorrected"), ("esc", "back")])
        }
        .onKeyPress(.character("p")) { _ in proceedUncorrected(); return .handled }
        .onKeyPress(.escape) { _ in goBack(); return .handled }
    }

    /// Re-runs the transcription with no corrector. A failed correction wrote
    /// no transcript, so there is nothing to reuse: transcribing again without
    /// Claude is the one way to continue.
    private func proceedUncorrected() {
        Task { await transcribe(corrector: nil) }
    }

    /// Dismisses the failure and returns to the input screen, keeping the
    /// user's choices so they can fix the problem and try again.
    private func goBack() {
        model.correctionFailure = nil
        model.screen = .input
    }

    private func stageRow(_ label: String, fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 1) {
                Spinner()
                Text(" \(label)").foregroundStyle(.secondary)
            }
            ProgressView(value: fraction).tint(Theme.accent)
            Text("\(Int((fraction * 100).rounded()))%").foregroundStyle(.secondary)
        }
    }

    /// Transcribes the video with Claude correction when the user turned it on,
    /// otherwise on-device only.
    private func run() async {
        await transcribe(corrector: model.correctionEnabled ? ClaudeCorrector() : nil)
    }

    /// Transcribes the video, then moves to the language screen with the
    /// resulting `.srt`. A `CorrectorError` is shown on this screen so the user
    /// can proceed uncorrected or go back; any other failure sets
    /// `model.errorMessage` and returns to the input screen.
    private func transcribe(corrector: (any TranscriptCorrecting)?) async {
        guard let video = model.videoURL else {
            model.screen = .input
            return
        }
        model.transcriptionStage = nil
        model.correctionFailure = nil
        let model = model
        do {
            let srt = try await TranscriptionJob(transcriber: AppleTranscriber(), corrector: corrector)
                .run(video: video) { stage in
                    Task { @MainActor in model.transcriptionStage = stage }
                }
            let targets = await SystemLanguageAvailability()
                .installed(from: Locale.Language(identifier: "en"),
                           candidates: LanguageCatalog.candidates)
            model.discoveredFiles = [srt]
            model.availableTargets = targets
            model.screen = .languages
        } catch let error as CorrectorError {
            model.correctionFailure = CorrectionFailure(error)
        } catch {
            model.errorMessage = "\(error)"
            model.screen = .input
        }
    }
}
