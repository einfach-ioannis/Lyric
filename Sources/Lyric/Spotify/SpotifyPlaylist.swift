import Foundation

/// A simplified playlist from `GET /v1/me/playlists`.
nonisolated struct SpotifyPlaylist: Decodable, Sendable {
    let uri: String
    let name: String
    let images: [SpotifyImage]?
    let tracks: SpotifyTotal?
    /// Newer responses name the track reference `items` instead of `tracks`.
    let items: SpotifyTotal?

    var songCount: Int? {
        tracks?.total ?? items?.total
    }
}
