import Foundation

/// One page of `GET /v1/me/playlists`.
nonisolated struct SpotifyPlaylistPage: Decodable, Sendable {
    /// Spotify occasionally returns `null` entries for playlists it can't show.
    let items: [SpotifyPlaylist?]

    /// "Liked Songs" followed by the person's playlists.
    func summaries(userID: String, likedSongCount: Int?) -> [PlaylistSummary] {
        let liked = PlaylistSummary(
            id: "spotify:user:\(userID):collection",
            name: String(localized: "Liked Songs"),
            detail: likedSongCount.map(Self.songCountText) ?? String(localized: "Your saved songs"),
            artworkURL: nil,
            source: .spotify,
            isLikedSongs: true
        )
        let playlists = items.compactMap(\.self).map { playlist in
            PlaylistSummary(
                id: playlist.uri,
                name: playlist.name,
                // Spotify reports 0 for playlists it won't list songs of; say nothing then.
                detail: playlist.songCount.flatMap { $0 > 0 ? Self.songCountText($0) : nil } ?? "",
                artworkURL: playlist.images?.first?.url,
                source: .spotify
            )
        }
        return [liked] + playlists
    }

    static func songCountText(_ count: Int) -> String {
        count == 1 ? String(localized: "1 song") : String(localized: "\(count) songs")
    }
}
