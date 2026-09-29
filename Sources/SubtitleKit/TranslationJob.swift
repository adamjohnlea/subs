import Foundation

/// The result of translating one file into one language.
public struct JobOutcome: Sendable {
    /// The source file this outcome belongs to.
    public let input: URL
    /// The language the file was translated into.
    public let target: TargetLanguage
    /// The written output file, or `nil` if the unit failed.
    public let output: URL?
    /// A description of the failure, or `nil` if the unit succeeded.
    public let errorMessage: String?
}

/// Progress after each unit (one file × one language) finishes.
public struct JobProgress: Sendable {
    /// The number of units finished so far.
    public let completedUnits: Int
    /// The total number of units (files times languages).
    public let totalUnits: Int
    /// The name of the file most recently processed.
    public let currentFile: String
    /// The display name of the language most recently processed.
    public let currentLanguage: String
}

/// Errors raised by the orchestrator itself (as opposed to parsing or translating).
public enum TranslationJobError: Error, Equatable {
    /// The translator returned a different number of lines than it was given.
    case lineCountMismatch(expected: Int, got: Int)
}

/// Translates subtitle files into one or more languages and writes the results next to the originals.
public struct TranslationJob {
    private let discovery: FileDiscovery
    private let parser: SRTParser
    private let writer: SRTWriter
    private let translator: Translating
    private let source: Locale.Language

    /// Creates a job with its collaborators; the defaults use the real file system and Apple's translator.
    public init(
        discovery: FileDiscovery = FileDiscovery(),
        parser: SRTParser = SRTParser(),
        writer: SRTWriter = SRTWriter(),
        translator: Translating = AppleTranslator(),
        source: Locale.Language = Locale.Language(identifier: "en")
    ) {
        self.discovery = discovery
        self.parser = parser
        self.writer = writer
        self.translator = translator
        self.source = source
    }

    /// Translates every discovered file into every target, reporting progress after each unit.
    ///
    /// Failures are recorded per unit in the returned outcomes rather than thrown.
    ///
    /// - Parameters:
    ///   - paths: `.srt` files or folders to translate.
    ///   - targets: The languages to translate into.
    ///   - progress: Called after each file-and-language unit finishes.
    /// - Returns: One outcome per file and language.
    public func run(
        paths: [URL],
        targets: [TargetLanguage],
        progress: @Sendable (JobProgress) -> Void
    ) async -> [JobOutcome] {
        // Expand all inputs to concrete .srt files first.
        var files: [URL] = []
        var outcomes: [JobOutcome] = []
        for path in paths {
            do { files.append(contentsOf: try discovery.srtFiles(at: path)) }
            catch {
                for target in targets {
                    outcomes.append(JobOutcome(input: path, target: target,
                                               output: nil, errorMessage: "\(error)"))
                }
            }
        }

        let totalUnits = files.count * targets.count
        var completed = 0

        for file in files {
            let document: SubtitleDocument
            do {
                let text = try String(contentsOf: file, encoding: .utf8)
                document = try parser.parse(text)
            } catch {
                for target in targets {
                    completed += 1
                    progress(JobProgress(completedUnits: completed, totalUnits: totalUnits,
                                         currentFile: file.lastPathComponent,
                                         currentLanguage: target.displayName))
                    outcomes.append(JobOutcome(input: file, target: target,
                                               output: nil, errorMessage: "\(error)"))
                }
                continue
            }

            for target in targets {
                do {
                    let translated = try await translate(document, to: target)
                    let out = OutputPath.translatedURL(for: file, languageCode: target.code)
                    try writer.write(translated).write(to: out, atomically: true, encoding: .utf8)
                    outcomes.append(JobOutcome(input: file, target: target,
                                               output: out, errorMessage: nil))
                } catch {
                    outcomes.append(JobOutcome(input: file, target: target,
                                               output: nil, errorMessage: "\(error)"))
                }
                completed += 1
                progress(JobProgress(completedUnits: completed, totalUnits: totalUnits,
                                     currentFile: file.lastPathComponent,
                                     currentLanguage: target.displayName))
            }
        }
        return outcomes
    }

    private func translate(_ document: SubtitleDocument,
                           to target: TargetLanguage) async throws -> SubtitleDocument {
        // Flatten every cue's lines into one ordered array, translate once,
        // then rebuild cues by their original line counts.
        let flat = document.cues.flatMap { $0.textLines }
        let translated = try await translator.translate(flat, from: source, to: target.language)
        guard translated.count == flat.count else {
            throw TranslationJobError.lineCountMismatch(expected: flat.count, got: translated.count)
        }

        var cursor = 0
        var newCues: [Cue] = []
        for cue in document.cues {
            let count = cue.textLines.count
            let slice = Array(translated[cursor ..< cursor + count])
            cursor += count
            newCues.append(Cue(index: cue.index, start: cue.start, end: cue.end, textLines: slice))
        }
        return SubtitleDocument(cues: newCues)
    }
}
