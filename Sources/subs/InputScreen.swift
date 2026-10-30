import Foundation
import SubtitleKit
import SwiftTUI

/// The first screen: the user types a `.srt` file, a video, or a folder path, and
/// Continue routes a video to transcription and anything else to language selection.
///
/// Validation is the real work of the app's first step: `FileDiscovery` must
/// find at least one `.srt` file, and `SystemLanguageAvailability` decides
/// which target languages are offered next. Any failure stays on this screen
/// and is shown as a ✗ line inside the Input card.
struct InputScreen: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Wordmark()
            Text("on-device subtitle translation").foregroundStyle(.secondary)
            StepTracker(active: .input)
            VStack(alignment: .leading, spacing: 1) {
                Text("Drop a .srt file, a video, or a folder, or type a path:")
                HStack(spacing: 0) {
                    Text("▸ ").foregroundStyle(Theme.accent)
                    TextField("path", text: $model.inputPath)
                        .onSubmit { Task { await advance() } }
                }
                correctionRow
                if let error = model.errorMessage {
                    Text("✗ \(error)").foregroundStyle(.danger)
                }
            }
            .card("Input")
            Button("Continue") { Task { await advance() } }
                .foregroundStyle(Theme.accent)
            HintFooter(hints: [("↵", "continue"), ("^C", "quit")])
        }
    }

    /// The opt-in row for Claude correction. Off by default; the button flips it.
    private var correctionRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 1) {
                Text("Claude correction: ")
                Text(model.correctionEnabled ? "on" : "off")
                    .foregroundStyle(model.correctionEnabled
                                     ? AnyShapeStyle(Theme.accent)
                                     : AnyShapeStyle(.secondary))
                Button(model.correctionEnabled ? "Turn off" : "Turn on") { toggleCorrection() }
                    .foregroundStyle(Theme.accent)
            }
            if model.correctionEnabled {
                Text("Videos only: sends the English transcript to the Claude API. Needs a key (subs set-claude-key).")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Flips Claude correction on or off.
    private func toggleCorrection() {
        model.correctionEnabled.toggle()
    }

    /// Routes a video to transcription; otherwise discovers subtitle files and the installed target
    /// languages, then moves to the language screen. On failure it sets
    /// `model.errorMessage` and stays on this screen.
    private func advance() async {
        model.errorMessage = nil
        // Undo terminal drag/paste escaping (backslash-escaped spaces, quotes)
        // before the string becomes a file URL.
        let path = normalizedInputPath(model.inputPath)
        guard !path.isEmpty else {
            model.errorMessage = "Enter a file or folder path."
            return
        }
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        switch inputKind(forExtension: url.pathExtension, isDirectory: isDirectory.boolValue) {
        case .video:
            model.videoURL = url
            model.isVideoFlow = true
            model.screen = .transcribing
        case .subtitles:
            do {
                let files = try FileDiscovery().srtFiles(at: url)
                let targets = await SystemLanguageAvailability()
                    .installed(from: Locale.Language(identifier: "en"),
                               candidates: LanguageCatalog.candidates)
                model.discoveredFiles = files
                model.availableTargets = targets
                model.isVideoFlow = false
                model.screen = .languages
            } catch {
                model.errorMessage = "\(error)"
            }
        }
    }
}
