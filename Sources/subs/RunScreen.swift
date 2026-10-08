import SubtitleKit
import SwiftTUI

/// The third screen: runs the translation job and shows live progress.
///
/// The job starts when the view appears. When it finishes, the outcomes are
/// stored on the model and the app moves to the done screen.
struct RunScreen: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            CompactHeader(step: .translate)
            VStack(alignment: .leading, spacing: 1) {
                if let progress = model.progress {
                    let line = progressLine(completedUnits: progress.completedUnits,
                                            totalUnits: progress.totalUnits)
                    HStack(spacing: 1) {
                        Spinner()
                        Text(" \(progress.currentFile)")
                        Text(" → ").foregroundStyle(.secondary)
                        Text(progress.currentLanguage)
                    }
                    ProgressView(value: line.fraction)
                        .tint(Theme.accent)
                    Text("\(line.percentText)   \(line.countText)").foregroundStyle(.secondary)
                    // Completed units, newest first, in a fixed-height box that
                    // scrolls instead of growing the card as the list fills.
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 1) {
                            ForEach(activityLines(model.progressLog), id: \.id) { line in
                                Text("✓ \(line.text)").foregroundStyle(.success)
                            }
                        }
                    }
                    .frame(height: activityBoxHeight)
                } else {
                    HStack(spacing: 1) {
                        Spinner()
                        Text(" Starting…").foregroundStyle(.secondary)
                    }
                }
            }
            .card("Translating")
            HintFooter(hints: [("^C", "cancel")])
        }
        .task { await run() }
    }

    private func run() async {
        model.progressLog = []
        let job = TranslationJob()
        let targets = Array(model.selectedTargets)
        let model = model
        let outcomes = await job.run(paths: model.discoveredFiles, targets: targets) { progress in
            Task { @MainActor in
                model.progress = progress
                model.progressLog.append("\(progress.currentFile) → \(progress.currentLanguage)")
            }
        }
        model.outcomes = outcomes
        model.screen = .done
    }
}
