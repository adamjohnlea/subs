import SubtitleKit
import SwiftTUI

/// The final screen: lists the result of every file and language pair, and
/// offers to start over.
struct DoneScreen: View {
    @Bindable var model: AppModel

    var body: some View {
        let rows = doneRows(model.outcomes)
        let summary = doneSummary(model.outcomes)
        return VStack(alignment: .leading, spacing: 1) {
            CompactHeader(step: .done)
            VStack(alignment: .leading, spacing: 1) {
                ForEach(rows) { row in
                    if row.kind == .success {
                        Text("✓ \(row.primary)").foregroundStyle(.success)
                    } else {
                        HStack(spacing: 1) {
                            Text("✗ \(row.primary)").foregroundStyle(.danger)
                            Text("  \(row.code ?? "")  ").foregroundStyle(.secondary)
                            Text(row.reason ?? "failed").foregroundStyle(.danger)
                        }
                    }
                }
                HStack(spacing: 1) {
                    Text("\(summary.written) written").foregroundStyle(.success)
                    Text(" · ").foregroundStyle(.secondary)
                    Text("\(summary.failed) failed").foregroundStyle(.danger)
                    if let folder = summary.outputFolder {
                        Text(" · \(folder)").foregroundStyle(.secondary)
                    }
                }
            }
            .card("Done")
            Button("Translate more") { startOver() }
                .foregroundStyle(Theme.accent)
            HintFooter(hints: [("↵", "start over"), ("^C", "quit")])
        }
        .onKeyPress(.return) { _ in startOver(); return .handled }
    }

    /// Resets the run state and returns to the input screen. Shared by the
    /// "Translate more" button and the Return key.
    private func startOver() {
        model.progress = nil
        model.progressLog = []
        model.outcomes = []
        model.selectedTargets = []
        model.screen = .input
    }
}
