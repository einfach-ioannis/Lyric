import Foundation

/// The song currently loaded in a player.
nonisolated struct Track: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let source: PlayerSource
    let artworkURL: URL?
}
