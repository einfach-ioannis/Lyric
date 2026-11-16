import Foundation

/// A song in the Up Next list.
nonisolated struct QueueItem: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let artist: String
    let duration: TimeInterval
    let artworkURL: URL?
}
