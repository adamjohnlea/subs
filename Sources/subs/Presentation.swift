import SubtitleKit

/// The four screens the app moves through, as an ordered, labeled sequence for
/// the step tracker. Distinct from `AppModel.Screen`, which drives routing.
enum Step: Int, CaseIterable {
    case input, languages, translate, done

    var label: String {
        switch self {
        case .input: return "Choose input"
        case .languages: return "Languages"
        case .translate: return "Translate"
        case .done: return "Done"
        }
    }
}

/// One entry in the step tracker: its label and whether it is the current step.
struct StepItem: Equatable {
    let label: String
    let isActive: Bool
}

/// The four step-tracker entries, with `active` marked.
func stepItems(active: Step) -> [StepItem] {
    Step.allCases.map { StepItem(label: $0.label, isActive: $0 == active) }
}

extension AppModel.Screen {
    /// The tracker step this routing screen corresponds to.
    var step: Step {
        switch self {
        case .input: return .input
        case .languages: return .languages
        case .running: return .translate
        case .done: return .done
        }
    }
}

/// The pieces the run screen needs to draw progress: a 0...1 fraction for the
/// bar, a percentage string, and a "completed of total" unit count.
struct ProgressLine: Equatable {
    let fraction: Double
    let percentText: String
    let countText: String
}

/// Formats overall progress from the job's unit counts. A unit is one file
/// translated into one language.
func progressLine(completedUnits: Int, totalUnits: Int) -> ProgressLine {
    let fraction = totalUnits > 0 ? Double(completedUnits) / Double(totalUnits) : 0
    let percent = Int((fraction * 100).rounded())
    return ProgressLine(
        fraction: fraction,
        percentText: "\(percent)%",
        countText: "\(completedUnits) of \(totalUnits)"
    )
}
