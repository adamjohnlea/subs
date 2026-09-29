import Foundation
import SubtitleKit
import SwiftTUI

/// The first screen: the user types a `.srt` file or a folder path, and
/// Continue validates it before moving on to language selection.
///
/// Validation is the real work of the app's first step: `FileDiscovery` must
/// find at least one `.srt` file, and `SystemLanguageAvailability` decides
/// which target languages are offered next. Any failure stays on this screen
/// and is shown on the `Error:` line.
struct InputScreen: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Enter a .srt file or a folder path:")
            TextField("path", text: $model.inputPath)
            if let error = model.errorMessage {
                Text("Error: \(error)")
            }
            Button("Continue") { Task { await advance() } }
        }
        .padding()
    }

    /// Discovers subtitle files at the typed path and the installed target
    /// languages, then moves to the language screen. On failure it sets
    /// `model.errorMessage` and stays on this screen.
    private func advance() async {
        model.errorMessage = nil
        let url = URL(fileURLWithPath: (model.inputPath as NSString).expandingTildeInPath)
        do {
            let files = try FileDiscovery().srtFiles(at: url)
            let targets = await SystemLanguageAvailability()
                .installed(from: Locale.Language(identifier: "en"),
                           candidates: LanguageCatalog.candidates)
            model.discoveredFiles = files
            model.availableTargets = targets
            model.screen = .languages
        } catch {
            model.errorMessage = "\(error)"
        }
    }
}
