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

    /// Target-language codes an output file can carry, used to skip previously translated files
    /// during folder discovery (e.g. `movie.es.srt`).
    private static let languageCodes: Set<String> =
        Set(LanguageCatalog.candidates.map { $0.code.lowercased() })

    /// Returns the `.srt` files at a path: a single `.srt` file returns itself; a folder is walked
    /// recursively for its visible `.srt` files (directories and hidden files excluded), sorted by
    /// path so files stay grouped by folder.
    ///
    /// During folder discovery, files that already carry a target-language suffix (e.g. `movie.es.srt`)
    /// are skipped, so re-running a folder does not re-translate prior outputs. A file passed directly
    /// is always honored, even when it carries such a suffix. Folder discovery also skips
    /// `film.original.srt`, the uncorrected transcript kept beside a Claude-corrected `film.srt`.
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
        guard let enumerator = fileManager.enumerator(
            at: path,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]) else {
            throw SubtitleDiscoveryError.noSRTFiles(path)
        }
        let srts = enumerator.compactMap { $0 as? URL }
            .filter { $0.pathExtension.lowercased() == "srt" }
            .filter { url in
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
                return values?.isDirectory != true
            }
            .filter { !Self.isAlreadyTranslated($0) }
            .filter { !Self.isOriginalTranscript($0) }
            .sorted { $0.path < $1.path }
        guard !srts.isEmpty else { throw SubtitleDiscoveryError.noSRTFiles(path) }
        return srts
    }

    /// Whether `url` is the uncorrected transcript (`film.original.srt`) saved beside a corrected one.
    /// Folder discovery skips it so the uncorrected text is never translated.
    private static func isOriginalTranscript(_ url: URL) -> Bool {
        url.lastPathComponent.lowercased().hasSuffix(".original.srt")
    }

    /// Whether `url` looks like an output this app produced, i.e. its name ends in
    /// `.<languageCode>.srt` for a known target language.
    private static func isAlreadyTranslated(_ url: URL) -> Bool {
        let suffix = url.deletingPathExtension().pathExtension.lowercased()
        return languageCodes.contains(suffix)
    }
}
