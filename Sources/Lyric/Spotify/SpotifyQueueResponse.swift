import Foundation

/// `GET /v1/me/player/queue`.
nonisolated struct SpotifyQueueResponse: Decodable, Sendable {
    let queue: [SpotifyQueueEntry?]?

    /// Upcoming songs; positions keep repeated tracks distinct.
    func items() -> [QueueItem] {
        (queue ?? []).compactMap(\.self).enumerated().map { position, entry in
            entry.queueItem(position: position)
        }
    }
}
