import Foundation

/// The parts of `GET /v1/me` Lyric uses.
nonisolated struct SpotifyUserProfile: Decodable, Sendable {
    let id: String
    let displayName: String?
}
