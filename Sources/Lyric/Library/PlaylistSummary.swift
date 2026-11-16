import Foundation

/// A playlist the person can switch to from the Playlists tab.
nonisolated struct PlaylistSummary: Identifiable, Equatable, Sendable {
    /// Spotify URI (`spotify:playlist:…`) or the Music playlist's persistent ID.
    let id: String
    let name: String
    /// Secondary line, e.g. "86 songs". Empty when there is nothing useful to say.
    let detail: String
    let artworkURL: URL?
    let source: PlayerSource
    /// Spotify's Liked Songs, drawn with its own heart artwork.
    var isLikedSongs = false
}
