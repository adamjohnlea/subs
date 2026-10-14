import Foundation

/// One transcribed word with its start and end time in seconds, in the media's
/// own timeline.
public struct TranscribedWord: Equatable, Sendable {
    public let text: String
    public let start: Double
    public let end: Double
    public init(text: String, start: Double, end: Double) {
        self.text = text
        self.start = start
        self.end = end
    }
}

/// Groups timed words into readable subtitle cues.
public enum CueBuilder {
    private static let maxDuration = 7.0    // longest a cue stays on screen
    private static let minDuration = 1.0    // shortest a cue stays on screen, room permitting
    private static let pauseBreak = 0.8     // a silence at least this long starts a new cue
    private static let gap = 0.1            // kept between a stretched cue and the next

    /// A non-empty run of words that will become one cue.
    private struct Group {
        let text: String
        let start: Double
        let end: Double

        /// Returns nil for an empty run, which the grouping loop never produces.
        init?(_ words: [TranscribedWord]) {
            guard let first = words.first, let last = words.last else { return nil }
            self.text = words.map(\.text).joined(separator: " ")
            self.start = first.start
            self.end = last.end
        }
    }

    /// Groups words, in the order heard, into cues. A new cue starts after a
    /// pause of `pauseBreak`+, after a sentence ends once the cue has been up
    /// `minDuration`, when the next word would not fit two lines, or past
    /// `maxDuration`. Short cues stretch to `minDuration` but never into the next.
    ///
    /// - Parameter words: Timed words in the order they were spoken.
    /// - Returns: Numbered cues with SRT timestamps and wrapped text lines.
    public static func cues(from words: [TranscribedWord]) -> [Cue] {
        var groups: [Group] = []
        var current: [TranscribedWord] = []

        for word in words {
            if let first = current.first, let last = current.last {
                let candidate = (current + [word]).map(\.text).joined(separator: " ")
                let endsSentence = last.text.last.map { ".?!".contains($0) } ?? false
                let startsNewCue = word.start - last.end >= pauseBreak
                    || (endsSentence && last.end - first.start >= minDuration)
                    || !SubtitleLayout.fits(candidate)
                    || word.end - first.start > maxDuration
                if startsNewCue {
                    if let group = Group(current) { groups.append(group) }
                    current = []
                }
            }
            current.append(word)
        }
        if let group = Group(current) { groups.append(group) }

        // End times in seconds, with the min-duration stretch that never overruns the next cue.
        var ends: [Double] = groups.map(\.end)
        for index in groups.indices {
            var end = max(ends[index], groups[index].start + minDuration)
            if index + 1 < groups.count {
                end = min(end, groups[index + 1].start - gap)
            }
            ends[index] = max(end, groups[index].end)
        }

        return groups.enumerated().map { index, group in
            Cue(index: index + 1,
                start: srtTimestamp(group.start),
                end: srtTimestamp(ends[index]),
                textLines: SubtitleLayout.wrap(group.text))
        }
    }
}
