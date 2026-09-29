import SwiftTUIRuntime

/// The app's root view. It owns the single `AppModel`, injects it into the
/// environment so every screen reads the same instance with
/// `@Environment(AppModel.self)`, and routes to the screen for `model.screen`.
///
/// The individual screens are filled in by later tasks; for now each case
/// renders its name so the shell launches and the routing is visible.
struct RootView: View {
    @State private var model = AppModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("subs — on-device subtitle translation")
            currentScreen
        }
        .environment(model)
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch model.screen {
        case .input:
            Text("screen: input")
        case .languages:
            Text("screen: languages")
        case .running:
            Text("screen: running")
        case .done:
            Text("screen: done")
        }
    }
}
