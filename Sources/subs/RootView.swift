import SwiftTUI

/// The app's root view. It owns the single `AppModel` and routes to the screen
/// for `model.screen`. Each screen renders its own header, so there is no
/// shared title line here anymore.
struct RootView: View {
    @State private var model = AppModel()

    var body: some View {
        currentScreen.padding()
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch model.screen {
        case .input:     InputScreen(model: model)
        case .languages: LanguageScreen(model: model)
        case .running:   RunScreen(model: model)
        case .done:      DoneScreen(model: model)
        }
    }
}
