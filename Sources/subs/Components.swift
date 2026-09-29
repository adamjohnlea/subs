import SwiftTUI

/// The slant FIGlet "subs" banner in the accent color. Input screen only.
struct Wordmark: View {
    var body: some View {
        TextFigure("subs", font: .slant)
            .foregroundStyle(Theme.accent)
    }
}

/// The 1-2-3-4 wayfinding row. The active step is a filled accent dot with a
/// foreground label; the rest are muted open dots and muted labels.
struct StepTracker: View {
    let active: Step
    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(stepItems(active: active).enumerated()), id: \.offset) { _, item in
                Text(item.isActive ? "● " : "○ ")
                    .foregroundStyle(item.isActive ? AnyShapeStyle(Theme.accent)
                                                    : AnyShapeStyle(.secondary))
                Text("\(item.label)   ")
                    .foregroundStyle(item.isActive ? AnyShapeStyle(.foreground)
                                                    : AnyShapeStyle(.secondary))
            }
        }
    }
}

/// The compact header shown on every screen after input: "subs ▸" then the
/// step tracker.
struct CompactHeader: View {
    let step: Step
    var body: some View {
        HStack(spacing: 1) {
            Text("subs").foregroundStyle(Theme.accent).bold()
            Text(" ▸  ").foregroundStyle(.secondary)
            StepTracker(active: step)
        }
    }
}

/// One muted line of key hints. Keys render in the accent color, labels muted.
struct HintFooter: View {
    let hints: [(key: String, label: String)]
    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(hints.enumerated()), id: \.offset) { _, hint in
                Text(hint.key).foregroundStyle(Theme.accent)
                Text(" \(hint.label)   ").foregroundStyle(.secondary)
            }
        }
    }
}

extension View {
    /// Wraps content in a rounded accent-dim border with a short accent title
    /// above it and interior padding. SwiftTUI draws a plain rounded border, so
    /// the title sits on its own line above the box rather than inset into it.
    func card(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).foregroundStyle(Theme.accent).bold()
            self.padding().border(Theme.accentDim, style: .rounded)
        }
    }
}
