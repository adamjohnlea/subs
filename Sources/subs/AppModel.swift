import Foundation
import Observation
import SubtitleKit

/// The whole app is a four-screen state machine. `AppModel` owns the screen
/// the user is on and every field the screens read and write, so the screen
/// views stay thin and share one source of truth.
///
/// It is a `@MainActor @Observable final class`: SwiftTUI tracks reads made in
/// a view `body` and invalidates exactly the views that read a property that
/// changed. `@MainActor` makes it implicitly `Sendable`, which SwiftTUI's
/// environment storage requires.
@MainActor
@Observable
final class AppModel {
    /// The screens the app moves through, in order.
    enum Screen: Equatable {
        case input
        case languages
        case running
        case done
    }

    /// The screen currently on display.
    var screen: Screen = .input

    /// The path the user typed on the input screen (a file or a directory).
    var inputPath: String = ""

    /// The `.srt` files discovered under `inputPath`.
    var discoveredFiles: [URL] = []

    /// Target languages whose translation packs are installed and offerable.
    var availableTargets: [TargetLanguage] = []

    /// The targets the user has selected to translate into.
    var selectedTargets: Set<TargetLanguage> = []

    /// Progress of the running job, or `nil` before it starts.
    var progress: JobProgress?

    /// A human-readable line for each completed unit (file → language), newest
    /// last. View-only state for the run screen's activity list.
    var progressLog: [String] = []

    /// The per-file, per-language results once the job finishes.
    var outcomes: [JobOutcome] = []

    /// A message to surface to the user when something goes wrong.
    var errorMessage: String?
}
