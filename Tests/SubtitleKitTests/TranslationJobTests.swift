import Foundation
import Testing
@testable import SubtitleKit

/// Deterministic fake: uppercases each non-blank line so we can assert mapping.
private struct FakeTranslator: Translating {
    func translate(_ lines: [String], from: Locale.Language, to: Locale.Language) async throws -> [String] {
        lines.map { $0.isEmpty ? $0 : $0.uppercased() }
    }
}

private struct FailingTranslator: Translating {
    func translate(_ lines: [String], from: Locale.Language, to: Locale.Language) async throws -> [String] {
        throw TranslatorError.notInstalled(target: to)
    }
}

/// Thread-safe collector so a `@Sendable` progress closure can record values under strict concurrency.
private final class ProgressBox: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Int] = []
    func append(_ value: Int) { lock.lock(); values.append(value); lock.unlock() }
    var snapshot: [Int] { lock.lock(); defer { lock.unlock() }; return values }
}

private func makeTempDir() throws -> URL {
    let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

private let es = TargetLanguage(code: "es", displayName: "Spanish")

@Test func translatesFileAndWritesSuffixedOutput() async throws {
    let dir = try makeTempDir()
    let input = dir.appendingPathComponent("film.srt")
    try "1\n00:00:01,000 --> 00:00:04,000\nHello".write(to: input, atomically: true, encoding: .utf8)

    let job = TranslationJob(translator: FakeTranslator())
    let outcomes = await job.run(paths: [input], targets: [es]) { _ in }

    #expect(outcomes.count == 1)
    let out = try #require(outcomes[0].output)
    #expect(out.lastPathComponent == "film.es.srt")
    let written = try String(contentsOf: out, encoding: .utf8)
    #expect(written.contains("HELLO"))
    #expect(written.contains("00:00:01,000 --> 00:00:04,000"))
}

@Test func reportsProgressPerUnit() async throws {
    let dir = try makeTempDir()
    let input = dir.appendingPathComponent("a.srt")
    try "1\n00:00:01,000 --> 00:00:02,000\nHi".write(to: input, atomically: true, encoding: .utf8)

    let job = TranslationJob(translator: FakeTranslator())
    let seen = ProgressBox()
    _ = await job.run(paths: [input], targets: [es]) { seen.append($0.completedUnits) }
    #expect(seen.snapshot.last == 1)
}

@Test func failedUnitIsRecordedWithoutKillingBatch() async throws {
    let dir = try makeTempDir()
    let good = dir.appendingPathComponent("a.srt")
    try "1\n00:00:01,000 --> 00:00:02,000\nHi".write(to: good, atomically: true, encoding: .utf8)

    let job = TranslationJob(translator: FailingTranslator())
    let outcomes = await job.run(paths: [good], targets: [es]) { _ in }
    #expect(outcomes.count == 1)
    #expect(outcomes[0].output == nil)
    #expect(outcomes[0].errorMessage != nil)
}

/// Violates the `Translating` contract by returning fewer lines than it was given.
private struct ShortChangingTranslator: Translating {
    func translate(_ lines: [String], from: Locale.Language, to: Locale.Language) async throws -> [String] {
        Array(lines.dropLast())
    }
}

/// Succeeds (uppercasing) for Spanish, throws for every other target.
private struct SpanishOnlyTranslator: Translating {
    func translate(_ lines: [String], from: Locale.Language, to: Locale.Language) async throws -> [String] {
        guard to.languageCode?.identifier == "es" else { throw TranslatorError.notInstalled(target: to) }
        return lines.map { $0.isEmpty ? $0 : $0.uppercased() }
    }
}

private let fr = TargetLanguage(code: "fr", displayName: "French")

@Test func translatorReturningWrongCountIsCapturedNotCrash() async throws {
    let dir = try makeTempDir()
    let input = dir.appendingPathComponent("a.srt")
    try "1\n00:00:01,000 --> 00:00:02,000\nHi\nthere".write(to: input, atomically: true, encoding: .utf8)

    let job = TranslationJob(translator: ShortChangingTranslator())
    let outcomes = await job.run(paths: [input], targets: [es]) { _ in }

    #expect(outcomes.count == 1)
    #expect(outcomes[0].output == nil)
    #expect(outcomes[0].errorMessage != nil)
    #expect(!FileManager.default.fileExists(atPath: dir.appendingPathComponent("a.es.srt").path))
}

@Test func mixedBatchContinuesPastFailure() async throws {
    let dir = try makeTempDir()
    let input = dir.appendingPathComponent("film.srt")
    try "1\n00:00:01,000 --> 00:00:04,000\nHello".write(to: input, atomically: true, encoding: .utf8)

    let job = TranslationJob(translator: SpanishOnlyTranslator())
    let outcomes = await job.run(paths: [input], targets: [es, fr]) { _ in }

    #expect(outcomes.count == 2)
    let esOutcome = try #require(outcomes.first { $0.target.code == "es" })
    let frOutcome = try #require(outcomes.first { $0.target.code == "fr" })
    let out = try #require(esOutcome.output)
    #expect(esOutcome.errorMessage == nil)
    #expect(try String(contentsOf: out, encoding: .utf8).contains("HELLO"))
    #expect(frOutcome.output == nil)
    #expect(frOutcome.errorMessage != nil)
}

@Test func multiCueMultiLineRemapping() async throws {
    let dir = try makeTempDir()
    let input = dir.appendingPathComponent("m.srt")
    let source = """
    1
    00:00:01,000 --> 00:00:02,000
    first line
    second line

    2
    00:00:03,000 --> 00:00:04,500
    third line
    """
    try source.write(to: input, atomically: true, encoding: .utf8)

    let job = TranslationJob(translator: FakeTranslator())
    let outcomes = await job.run(paths: [input], targets: [es]) { _ in }

    let out = try #require(outcomes.first?.output)
    let doc = try SRTParser().parse(String(contentsOf: out, encoding: .utf8))
    #expect(doc.cues.count == 2)
    #expect(doc.cues[0].index == 1)
    #expect(doc.cues[0].start == "00:00:01,000")
    #expect(doc.cues[0].end == "00:00:02,000")
    #expect(doc.cues[0].textLines == ["FIRST LINE", "SECOND LINE"])
    #expect(doc.cues[1].index == 2)
    #expect(doc.cues[1].start == "00:00:03,000")
    #expect(doc.cues[1].end == "00:00:04,500")
    #expect(doc.cues[1].textLines == ["THIRD LINE"])
}
