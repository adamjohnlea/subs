import Foundation

/// Computes where translated subtitle files are written.
public enum OutputPath {
    /// Returns the translated file's URL, next to the input: `/movies/film.srt` + "es" -> `/movies/film.es.srt`.
    ///
    /// - Parameters:
    ///   - input: The source `.srt` file URL.
    ///   - languageCode: The target language code inserted before the extension.
    public static func translatedURL(for input: URL, languageCode: String) -> URL {
        let directory = input.deletingLastPathComponent()
        let ext = input.pathExtension                 // "srt"
        let stem = input.deletingPathExtension().lastPathComponent
        let name = "\(stem).\(languageCode).\(ext)"
        return directory.appendingPathComponent(name)
    }
}
