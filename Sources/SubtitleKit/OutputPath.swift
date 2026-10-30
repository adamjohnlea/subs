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

    /// The English transcript's URL: the video's path with its extension swapped
    /// for `.srt` (`/movies/film.mp4` -> `/movies/film.srt`).
    public static func transcriptURL(forVideo video: URL) -> URL {
        video.deletingPathExtension().appendingPathExtension("srt")
    }

    /// Where the uncorrected transcript is kept: `/movies/film.srt` -> `/movies/film.original.srt`.
    public static func originalTranscriptURL(forTranscript transcript: URL) -> URL {
        transcript.deletingPathExtension().appendingPathExtension("original.srt")
    }

    /// Where the correction changelog is written: `/movies/film.srt` -> `/movies/film.corrections.md`.
    public static func correctionsURL(forTranscript transcript: URL) -> URL {
        transcript.deletingPathExtension().appendingPathExtension("corrections.md")
    }
}
