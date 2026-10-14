import AVFoundation
import Foundation
import Speech

/// A step of transcription, for progress reporting.
public enum TranscriptionStage: Equatable, Sendable {
    /// The English speech model is downloading, `fraction` (0...1) done.
    case downloadingModel(fraction: Double)
    /// The audio is being transcribed, `fraction` (0...1) of the way through.
    case transcribing(fraction: Double)
}

/// Errors raised while transcribing a video.
public enum TranscriberError: Error, Equatable {
    /// On-device transcription is not available on this Mac.
    case unavailable
    /// The file has no audio track to transcribe.
    case noAudioTrack
    /// The audio contained no recognizable speech.
    case noSpeechFound
    /// The speech-model reservation cap is full and English is not reserved.
    case modelReservationFull(held: [String])
    /// The audio could not be extracted from the file for transcription.
    case audioExtractionFailed
}

/// Transcribes a video's speech into timed words.
public protocol Transcribing: Sendable {
    func transcribe(video: URL,
                    progress: @Sendable @escaping (TranscriptionStage) -> Void) async throws -> [TranscribedWord]
}

/// Transcribes a video's speech into timed words using Apple's on-device
/// `SpeechAnalyzer`. English only; the model is downloaded on first use.
public struct AppleTranscriber: Transcribing {
    public init() {}

    public func transcribe(video: URL,
                           progress: @Sendable @escaping (TranscriptionStage) -> Void) async throws -> [TranscribedWord] {
        guard SpeechTranscriber.isAvailable else { throw TranscriberError.unavailable }
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US")) else {
            throw TranscriberError.unavailable
        }
        let asset = AVURLAsset(url: video)
        guard try await asset.loadTracks(withMediaType: .audio).first != nil else {
            throw TranscriberError.noAudioTrack
        }
        let duration = try await asset.load(.duration).seconds

        let audioURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")
        defer { try? FileManager.default.removeItem(at: audioURL) }
        try await extractAudio(from: asset, to: audioURL)
        let audioFile = try AVAudioFile(forReading: audioURL)

        try await installModelIfNeeded(locale: locale, progress: progress)

        let transcriber = SpeechTranscriber(locale: locale, transcriptionOptions: [],
                                            reportingOptions: [], attributeOptions: [.audioTimeRange])
        let analyzer = SpeechAnalyzer(modules: [transcriber])

        let collector = Task { () throws -> [TranscribedWord] in
            var words: [TranscribedWord] = []
            for try await result in transcriber.results {
                for (timeRange, range) in result.text.runs[\.audioTimeRange] {
                    let token = String(result.text[range].characters)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !token.isEmpty else { continue }
                    if let timeRange {
                        words.append(TranscribedWord(text: token,
                                                     start: timeRange.start.seconds,
                                                     end: timeRange.end.seconds))
                    } else if !words.isEmpty {
                        // Punctuation with no time range: attach to the previous word.
                        let last = words.removeLast()
                        words.append(TranscribedWord(text: last.text + token, start: last.start, end: last.end))
                    }
                    if duration > 0, let timeRange {
                        progress(.transcribing(fraction: min(1, timeRange.end.seconds / duration)))
                    }
                }
            }
            return words
        }

        // Cancelling the task does not stop the analyzer or the collector by itself, so a cancel ends
        // both, and every exit path below cancels the collector so it never outlives this call.
        do {
            return try await withTaskCancellationHandler {
                if let last = try await analyzer.analyzeSequence(from: audioFile) {
                    try await analyzer.finalizeAndFinish(through: last)
                } else {
                    await analyzer.cancelAndFinishNow()
                }
                try Task.checkCancellation()
                return try await collector.value
            } onCancel: {
                collector.cancel()
                Task { await analyzer.cancelAndFinishNow() }
            }
        } catch {
            collector.cancel()
            throw Task.isCancelled ? CancellationError() : error
        }
    }

    /// Exports the asset's audio to an `.m4a` file, since `AVAudioFile` cannot read a video container.
    private func extractAudio(from asset: AVURLAsset, to url: URL) async throws {
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw TranscriberError.audioExtractionFailed
        }
        try await session.export(to: url, as: .m4a)
    }

    /// Downloads and installs the English model if it is not already on this Mac,
    /// reserving the locale first as Apple requires. Reports `.downloadingModel`.
    private func installModelIfNeeded(locale: Locale,
                                      progress: @Sendable @escaping (TranscriptionStage) -> Void) async throws {
        let target = locale.identifier(.bcp47)
        let installed = await SpeechTranscriber.installedLocales.map { $0.identifier(.bcp47) }
        if installed.contains(target) { return }

        let reserved = await AssetInventory.reservedLocales.map { $0.identifier(.bcp47) }
        if !reserved.contains(target) {
            do { try await AssetInventory.reserve(locale: locale) }
            catch {
                let held = await AssetInventory.reservedLocales.map { $0.identifier(.bcp47) }
                throw TranscriberError.modelReservationFull(held: held)
            }
        }
        let modelProbe = SpeechTranscriber(locale: locale, transcriptionOptions: [],
                                           reportingOptions: [], attributeOptions: [.audioTimeRange])
        guard let request = try await AssetInventory.assetInstallationRequest(supporting: [modelProbe]) else { return }
        let observation = request.progress.observe(\.fractionCompleted, options: [.new]) { value, _ in
            progress(.downloadingModel(fraction: value.fractionCompleted))
        }
        defer { observation.invalidate() }
        try await request.downloadAndInstall()
    }
}
