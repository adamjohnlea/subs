import Foundation

public enum OutputPath {
    /// `/movies/film.srt` + "es" -> `/movies/film.es.srt`.
    public static func translatedURL(for input: URL, languageCode: String) -> URL {
        let directory = input.deletingLastPathComponent()
        let ext = input.pathExtension                 // "srt"
        let stem = input.deletingPathExtension().lastPathComponent
        let name = "\(stem).\(languageCode).\(ext)"
        return directory.appendingPathComponent(name)
    }
}
