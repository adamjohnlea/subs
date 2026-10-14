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

@Test func ignoresHiddenAppleDoubleFiles() throws {
    let dir = try makeTempDir()
    for name in ["._movie.srt", "a.srt"] {
        try "x".write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }
    let found = try FileDiscovery().srtFiles(at: dir)
    #expect(found.map(\.lastPathComponent) == ["a.srt"])
}

@Test func ignoresSubdirectoriesNamedLikeSRTs() throws {
    let dir = try makeTempDir()
    try FileManager.default.createDirectory(
        at: dir.appendingPathComponent("nested.srt"), withIntermediateDirectories: false)
    try "x".write(to: dir.appendingPathComponent("a.srt"), atomically: true, encoding: .utf8)
    let found = try FileDiscovery().srtFiles(at: dir)
    #expect(found.map(\.lastPathComponent) == ["a.srt"])
}

@Test func findsSRTsInNestedSubdirectories() throws {
    let root = try makeTempDir()
    let subA = root.appendingPathComponent("A")
    let subB = root.appendingPathComponent("B/deeper")
    try FileManager.default.createDirectory(at: subA, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: subB, withIntermediateDirectories: true)
    try "x".write(to: root.appendingPathComponent("top.srt"), atomically: true, encoding: .utf8)
    try "x".write(to: subA.appendingPathComponent("one.srt"), atomically: true, encoding: .utf8)
    try "x".write(to: subB.appendingPathComponent("two.srt"), atomically: true, encoding: .utf8)
    let found = try FileDiscovery().srtFiles(at: root)
    #expect(Set(found.map(\.lastPathComponent)) == ["top.srt", "one.srt", "two.srt"])
}

@Test func sortsNestedResultsByRelativePath() throws {
    let root = try makeTempDir()
    let subA = root.appendingPathComponent("A")
    let subB = root.appendingPathComponent("B")
    try FileManager.default.createDirectory(at: subA, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: subB, withIntermediateDirectories: true)
    try "x".write(to: subB.appendingPathComponent("z.srt"), atomically: true, encoding: .utf8)
    try "x".write(to: subA.appendingPathComponent("a.srt"), atomically: true, encoding: .utf8)
    try "x".write(to: root.appendingPathComponent("top.srt"), atomically: true, encoding: .utf8)
    let found = try FileDiscovery().srtFiles(at: root)
    // Grouped by folder path: A/ before B/ before the root file.
    #expect(found.map(\.lastPathComponent) == ["a.srt", "z.srt", "top.srt"])
}

@Test func skipsAlreadyTranslatedOutputsInFolder() throws {
    let dir = try makeTempDir()
    for name in ["movie.srt", "movie.es.srt", "movie.de.srt"] {
        try "x".write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }
    let found = try FileDiscovery().srtFiles(at: dir)
    #expect(found.map(\.lastPathComponent) == ["movie.srt"])
}

@Test func keepsFilesWhoseDottedSuffixIsNotALanguageCode() throws {
    let dir = try makeTempDir()
    // "mov (eng)" and "v2" are not language codes, so these are sources, not outputs.
    for name in ["clip.mov (eng).srt", "scene.v2.srt"] {
        try "x".write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }
    let found = try FileDiscovery().srtFiles(at: dir)
    #expect(Set(found.map(\.lastPathComponent)) == ["clip.mov (eng).srt", "scene.v2.srt"])
}

@Test func returnsExplicitTranslatedFileWhenPointedAtItDirectly() throws {
    let dir = try makeTempDir()
    let file = dir.appendingPathComponent("movie.es.srt")
    try "x".write(to: file, atomically: true, encoding: .utf8)
    // The skip guard applies to folder discovery only; an explicit file is honored.
    let found = try FileDiscovery().srtFiles(at: file)
    #expect(found.map(\.lastPathComponent) == ["movie.es.srt"])
}
