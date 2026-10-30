import AVFoundation
import Foundation
import Speech
import SubtitleKit

/// Transcribes a video's speech into timed words using Apple's on-device
/// `SpeechAnalyzer`. English only; the model is downloaded on first use.
///
/// This is the concrete `Transcribing` implementation. It lives in its own
/// module so that the Speech and AVFoundation frameworks stay out of
/// `SubtitleKit`, which remains pure Foundation.
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
                                            reportingOptions: [.alternativeTranscriptions],
                                            attributeOptions: [.audioTimeRange, .transcriptionConfidence])
        let analyzer = SpeechAnalyzer(modules: [transcriber])

        let collector = Task { () throws -> [TranscribedWord] in
            var words: [TranscribedWord] = []
            for try await result in transcriber.results {
                // The recognizer reports alternatives for the whole result, so each word built from this result carries them.
                let alternatives = result.alternatives.map { String($0.characters) }
                for (timeRange, confidence, range) in result.text.runs[\.audioTimeRange, \.transcriptionConfidence] {
                    let token = String(result.text[range].characters)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !token.isEmpty else { continue }
                    if let timeRange {
                        words.append(TranscribedWord(text: token,
                                                     start: timeRange.start.seconds,
                                                     end: timeRange.end.seconds,
                                                     confidence: confidence,
                                                     alternatives: alternatives))
                    } else if !words.isEmpty {
                        // Punctuation with no time range: attach to the previous word.
                        let last = words.removeLast()
                        words.append(TranscribedWord(text: last.text + token, start: last.start, end: last.end,
                                                     confidence: last.confidence, alternatives: last.alternatives))
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
        do {
            try await session.export(to: url, as: .m4a)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw TranscriberError.audioExtractionFailed
        }
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
                                           reportingOptions: [],
                                           attributeOptions: [.audioTimeRange, .transcriptionConfidence])
        guard let request = try await AssetInventory.assetInstallationRequest(supporting: [modelProbe]) else { return }
        let observation = request.progress.observe(\.fractionCompleted, options: [.new]) { value, _ in
            progress(.downloadingModel(fraction: value.fractionCompleted))
        }
        defer { observation.invalidate() }
        try await request.downloadAndInstall()
    }
}
