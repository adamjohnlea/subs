import Foundation

public enum SubtitleDiscoveryError: Error, Equatable {
    case notFound(URL)
    case noSRTFiles(URL)
}

public struct FileDiscovery {
    private let fileManager: FileManager
    public init(fileManager: FileManager = .default) { self.fileManager = fileManager }

    /// A single `.srt` path returns itself; a directory returns its `.srt`
    /// files (shallow), sorted by name. Recursion is a later addition.
    public func srtFiles(at path: URL) throws -> [URL] {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory) else {
            throw SubtitleDiscoveryError.notFound(path)
        }
        if !isDirectory.boolValue {
            guard path.pathExtension.lowercased() == "srt" else {
                throw SubtitleDiscoveryError.noSRTFiles(path)
            }
            return [path]
        }
        let contents = try fileManager.contentsOfDirectory(
            at: path, includingPropertiesForKeys: nil)
        let srts = contents
            .filter { $0.pathExtension.lowercased() == "srt" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        guard !srts.isEmpty else { throw SubtitleDiscoveryError.noSRTFiles(path) }
        return srts
    }
}
