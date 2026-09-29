import SwiftTUI

/// The app's root view. It owns the single `AppModel`,
/// passes it to every screen through its initializer, and routes to the screen
/// for `model.screen`.
struct RootView: View {
    @State private var model = AppModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("subs — on-device subtitle translation")
            currentScreen
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch model.screen {
        case .input:
            InputScreen(model: model)
        case .languages:
            LanguageScreen(model: model)
        case .running:
            RunScreen(model: model)
        case .done:
            DoneScreen(model: model)
        }
    }
}
