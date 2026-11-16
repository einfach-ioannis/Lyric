import Foundation

/// Artwork in one size; Spotify lists the largest first.
nonisolated struct SpotifyImage: Decodable, Sendable {
    let url: URL
}
