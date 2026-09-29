import Foundation

/// Reasons subtitle discovery can fail.
public enum SubtitleDiscoveryError: Error, Equatable {
    /// Nothing exists at the given path.
    case notFound(URL)
    /// The path is not an `.srt` file, or the folder contains none.
    case noSRTFiles(URL)
}

/// Finds `.srt` files at a file or folder path.
public struct FileDiscovery {
    private let fileManager: FileManager
    /// Creates a discovery helper that reads the file system through `fileManager`.
    public init(fileManager: FileManager = .default) { self.fileManager = fileManager }

    /// Returns the `.srt` files at a path: a single `.srt` file returns itself; a folder returns its
    /// visible `.srt` files (shallow, directories excluded), sorted by name.
    ///
    /// - Parameter path: An `.srt` file or a folder.
    /// - Throws: `SubtitleDiscoveryError` if the path is missing or yields no `.srt` files.
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
            at: path,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles])
        let srts = contents
            .filter { $0.pathExtension.lowercased() == "srt" }
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        guard !srts.isEmpty else { throw SubtitleDiscoveryError.noSRTFiles(path) }
        return srts
    }
}
