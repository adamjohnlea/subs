import SubtitleKit
import SwiftTUI

/// The second screen: pick one or more target languages to translate into.
///
/// Only languages whose translation packs are installed are offered
/// (`model.availableTargets`, filled by the input screen). When none are
/// installed the screen explains how to install them instead of showing an
/// empty list. Translate only advances when at least one language is selected.
struct LanguageScreen: View {
    @Bindable var model: AppModel

    var body: some View {
        if model.availableTargets.isEmpty {
            VStack(alignment: .leading, spacing: 1) {
                CompactHeader(step: .languages)
                VStack(alignment: .leading, spacing: 1) {
                    Text("No translation languages are installed.")
                    Text("Install them in System Settings > Language & Region > Translation Languages, then restart.")
                        .foregroundStyle(.secondary)
                }
                .card("Target languages")
                Button("Back") { model.screen = .input }
                    .foregroundStyle(Theme.accent)
                HintFooter(hints: [("↵", "back")])
            }
        } else {
            VStack(alignment: .leading, spacing: 1) {
                CompactHeader(step: .languages)
                VStack(alignment: .leading, spacing: 1) {
                    Text("space toggles  ·  enter continues").foregroundStyle(.secondary)
                    List(selection: $model.selectedTargets) {
                        ForEach(model.availableTargets, id: \.self) { target in
                            let isSelected = model.selectedTargets.contains(target)
                            HStack(spacing: 1) {
                                Text(isSelected ? "◉ " : "○ ")
                                    .foregroundStyle(isSelected
                                                     ? AnyShapeStyle(Theme.accent)
                                                     : AnyShapeStyle(.secondary))
                                Text(target.displayName)
                                Text("  \(target.code)").foregroundStyle(.secondary)
                            }
                            .tag(target)
                        }
                    }
                    if model.selectedTargets.isEmpty {
                        Text("Select at least one language.").foregroundStyle(.secondary)
                    } else {
                        Text("\(model.selectedTargets.count) selected").foregroundStyle(Theme.accent)
                    }
                }
                .card("Target languages")
                Button("Translate") {
                    if !model.selectedTargets.isEmpty { model.screen = .running }
                }
                .foregroundStyle(Theme.accent)
                Button("Back") { model.screen = .input }
                    .foregroundStyle(.secondary)
                HintFooter(hints: [("↑↓", "move"), ("space", "select"), ("↵", "translate"), ("esc", "back")])
            }
        }
    }
}
