import SubtitleKit
import SwiftTUI

/// The final screen: lists the result of every file and language pair, and
/// offers to start over.
struct DoneScreen: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Done.")
            ForEach(Array(model.outcomes.enumerated()), id: \.offset) { _, outcome in
                if let output = outcome.output {
                    Text("✓ \(output.lastPathComponent)")
                } else {
                    Text("✗ \(outcome.input.lastPathComponent) (\(outcome.target.code)): \(outcome.errorMessage ?? "failed")")
                }
            }
            Button("Translate more") {
                model.progress = nil
                model.outcomes = []
                model.selectedTargets = []
                model.screen = .input
            }
        }
        .padding()
    }
}
