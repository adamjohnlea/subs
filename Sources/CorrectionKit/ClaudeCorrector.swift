import Foundation
import SubtitleKit

/// Corrects transcripts by asking Claude over the Anthropic Messages API.
public struct ClaudeCorrector: TranscriptCorrecting {
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    private let keyStore: APIKeyStore
    private let session: URLSession

    /// Creates a corrector that reads the API key from `keyStore` and sends requests through `session`.
    public init(keyStore: APIKeyStore = KeychainAPIKeyStore(), session: URLSession = .shared) {
        self.keyStore = keyStore
        self.session = session
    }

    public func edits(for words: [TranscribedWord]) async throws -> [WordEdit] {
        guard let key = try keyStore.claudeKey() else { throw CorrectorError.noKey }

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.httpBody = CorrectionPrompt.requestBody(for: words)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw CorrectorError.transport(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else { throw CorrectorError.malformedResponse }

        return try CorrectionPrompt.parseEdits(from: data, httpStatus: http.statusCode)
    }
}
