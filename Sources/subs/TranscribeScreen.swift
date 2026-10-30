import Foundation
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
        .task { await run() }
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

    /// Transcribes the video, then moves to the language screen with the
    /// resulting `.srt`. On failure it sets `model.errorMessage` and returns to
    /// the input screen.
    private func run() async {
        guard let video = model.videoURL else {
            model.screen = .input
            return
        }
        model.transcriptionStage = nil
        let model = model
        do {
            let srt = try await TranscriptionJob(transcriber: AppleTranscriber()).run(video: video) { stage in
                Task { @MainActor in model.transcriptionStage = stage }
            }
            let targets = await SystemLanguageAvailability()
                .installed(from: Locale.Language(identifier: "en"),
                           candidates: LanguageCatalog.candidates)
            model.discoveredFiles = [srt]
            model.availableTargets = targets
            model.screen = .languages
        } catch {
            model.errorMessage = "\(error)"
            model.screen = .input
        }
    }
}
