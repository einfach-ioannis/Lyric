import Foundation

/// A track or podcast episode in the playback queue.
nonisolated struct SpotifyQueueEntry: Decodable, Sendable {
    let name: String
    let uri: String?
    let durationMs: Double?
    /// Tracks only.
    let artists: [SpotifyArtist]?
    let album: SpotifyAlbum?
    /// Episodes only.
    let show: SpotifyShow?
    let images: [SpotifyImage]?

    func queueItem(position: Int) -> QueueItem {
        let artistNames = artists?.map(\.name) ?? []
        return QueueItem(
            id: "\(position):\(uri ?? name)",
            title: name,
            artist: artistNames.isEmpty ? show?.name ?? "" : artistNames.formatted(),
            duration: (durationMs ?? 0) / 1000,
            artworkURL: album?.images?.first?.url ?? images?.first?.url ?? show?.images?.first?.url
        )
    }
}
