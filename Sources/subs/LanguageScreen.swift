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
                Text("No translation languages are installed.")
                Text("Install them in System Settings > Language & Region > Translation Languages, then restart.")
                Button("Back") { model.screen = .input }
            }
            .padding()
        } else {
            VStack(alignment: .leading, spacing: 1) {
                Text("Select target languages (space toggles, enter continues):")
                List(selection: $model.selectedTargets) {
                    ForEach(model.availableTargets, id: \.self) { target in
                        Text(target.displayName).tag(target)
                    }
                }
                Button("Translate") {
                    if !model.selectedTargets.isEmpty { model.screen = .running }
                }
            }
            .padding()
        }
    }
}
