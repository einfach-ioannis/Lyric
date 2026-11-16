import Foundation

/// Body of a failed `/api/token` call, e.g. `{"error": "invalid_grant", …}`.
nonisolated struct SpotifyAuthErrorResponse: Decodable, Sendable {
    let error: String
    let errorDescription: String?
}
