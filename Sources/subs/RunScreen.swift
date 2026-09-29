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
            Text("Translating…")
            if let progress = model.progress {
                Text("\(progress.completedUnits)/\(progress.totalUnits)  \(progress.currentFile) -> \(progress.currentLanguage)")
            }
        }
        .padding()
        .task { await run() }
    }

    private func run() async {
        let job = TranslationJob()
        let targets = Array(model.selectedTargets)
        let model = model
        let outcomes = await job.run(paths: model.discoveredFiles, targets: targets) { progress in
            Task { @MainActor in model.progress = progress }
        }
        model.outcomes = outcomes
        model.screen = .done
    }
}
