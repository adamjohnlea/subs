import Foundation
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

/// Whether a done-screen row is a written file or a failure.
enum DoneRowKind: Equatable { case success, failure }

/// One row on the done screen. Success rows carry only the output filename;
/// failure rows carry the source filename, the language code, and the reason.
struct DoneRow: Equatable, Identifiable {
    let id: Int
    let kind: DoneRowKind
    let primary: String
    let code: String?
    let reason: String?
}

/// Turns raw outcomes into ordered, displayable rows.
func doneRows(_ outcomes: [JobOutcome]) -> [DoneRow] {
    outcomes.enumerated().map { index, outcome in
        if let output = outcome.output {
            return DoneRow(id: index, kind: .success,
                           primary: output.lastPathComponent, code: nil, reason: nil)
        }
        return DoneRow(id: index, kind: .failure,
                       primary: outcome.input.lastPathComponent,
                       code: outcome.target.code,
                       reason: outcome.errorMessage ?? "failed")
    }
}

/// The counted summary line: how many were written, how many failed, and the
/// folder the outputs landed in (the first success's directory), if any.
struct DoneSummary: Equatable {
    let written: Int
    let failed: Int
    let outputFolder: String?
}

func doneSummary(_ outcomes: [JobOutcome]) -> DoneSummary {
    let written = outcomes.filter { $0.output != nil }.count
    let folder = outcomes.compactMap { $0.output?.deletingLastPathComponent().path }.first
    return DoneSummary(written: written, failed: outcomes.count - written, outputFolder: folder)
}

/// Row height of the scroll boxes that hold the run screen's live activity list
/// and the done screen's results list. Fixed so those cards stay a constant size
/// and their lists scroll within them rather than growing and clipping.
let activityBoxHeight = 16

/// One row in the run screen's completed-translation list: the text to show and
/// a stable identity. The id is the order the unit finished in, so a row keeps
/// its identity as newer rows are inserted above it — the list reorders without
/// re-rendering rows that have already settled.
struct ActivityLine: Equatable, Identifiable {
    let id: Int
    let text: String
}

/// The completed units as display rows, most recently finished first, so the
/// newest translation is always at the top of the scrollable list. `log` is the
/// append-ordered progress log (oldest first); the id preserves that completion
/// order while the display order is reversed.
func activityLines(_ log: [String]) -> [ActivityLine] {
    log.enumerated().reversed().map { ActivityLine(id: $0.offset, text: $0.element) }
}

/// Normalizes a path as it arrives from the input field, undoing the escaping a
/// terminal applies when a file or folder is dragged in or a path is pasted.
///
/// Dragging onto Terminal or iTerm escapes spaces and other shell
/// metacharacters with backslashes (`.../LUMINOR-\ Create\ a\ Camera`), and
/// some shells or apps wrap the whole path in single or double quotes. Both are
/// literal characters in the field, so feeding the raw string to
/// `URL(fileURLWithPath:)` looks for a name that still contains the backslashes
/// or quotes and fails. This returns the real on-disk path.
///
/// The rules follow POSIX shell quoting closely enough for a dropped path:
/// surrounding whitespace is trimmed; one layer of matching surrounding quotes
/// is removed; and backslash escapes (`\x` -> `x`) are undone on anything that
/// was not single-quoted (inside single quotes the shell keeps backslashes
/// literal). A hand-typed path with no backslashes or quotes passes through
/// unchanged.
func normalizedInputPath(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.count >= 2, let first = trimmed.first, let last = trimmed.last {
        if first == "'" && last == "'" {
            // Single quotes: contents are fully literal, so just unquote.
            return String(trimmed.dropFirst().dropLast())
        }
        if first == "\"" && last == "\"" {
            return unescapingShellBackslashes(String(trimmed.dropFirst().dropLast()))
        }
    }
    return unescapingShellBackslashes(trimmed)
}

/// Drops shell backslash escapes: each backslash is removed and the following
/// character kept literally (`\ ` -> space, `\\` -> `\`). A trailing lone
/// backslash is dropped.
private func unescapingShellBackslashes(_ s: String) -> String {
    var result = ""
    result.reserveCapacity(s.count)
    var iterator = s.makeIterator()
    while let character = iterator.next() {
        if character == "\\" {
            if let escaped = iterator.next() {
                result.append(escaped)
            }
        } else {
            result.append(character)
        }
    }
    return result
}
