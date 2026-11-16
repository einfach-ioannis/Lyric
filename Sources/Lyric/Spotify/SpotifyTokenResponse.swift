import Foundation

/// Body of a successful `/api/token` call.
nonisolated struct SpotifyTokenResponse: Decodable, Sendable {
    let accessToken: String
    let expiresIn: Int
    /// Missing on some refreshes, in which case the old refresh token stays valid.
    let refreshToken: String?
}
