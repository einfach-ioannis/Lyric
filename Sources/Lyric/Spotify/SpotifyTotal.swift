import Foundation

/// Any paging object reduced to its item count, e.g. a playlist's `tracks`.
nonisolated struct SpotifyTotal: Decodable, Sendable {
    let total: Int
}
