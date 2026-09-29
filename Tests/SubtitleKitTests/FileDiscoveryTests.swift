import Foundation
import Testing
@testable import SubtitleKit

private func makeTempDir() throws -> URL {
    let dir = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

@Test func returnsSingleFileWhenPathIsAnSRT() throws {
    let dir = try makeTempDir()
    let file = dir.appendingPathComponent("a.srt")
    try "x".write(to: file, atomically: true, encoding: .utf8)
    let found = try FileDiscovery().srtFiles(at: file)
    #expect(found.map(\.lastPathComponent) == ["a.srt"])
}

@Test func findsAllSRTsInDirectorySorted() throws {
    let dir = try makeTempDir()
    for name in ["b.srt", "a.srt", "notes.txt"] {
        try "x".write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }
    let found = try FileDiscovery().srtFiles(at: dir)
    #expect(found.map(\.lastPathComponent) == ["a.srt", "b.srt"])
}

@Test func throwsWhenNothingFound() throws {
    let missing = URL(fileURLWithPath: "/does/not/exist.srt")
    #expect(throws: SubtitleDiscoveryError.self) { try FileDiscovery().srtFiles(at: missing) }
}

@Test func throwsWhenDirectoryHasNoSRTs() throws {
    let dir = try makeTempDir()
    try "x".write(to: dir.appendingPathComponent("notes.txt"), atomically: true, encoding: .utf8)
    #expect(throws: SubtitleDiscoveryError.self) { try FileDiscovery().srtFiles(at: dir) }
}
