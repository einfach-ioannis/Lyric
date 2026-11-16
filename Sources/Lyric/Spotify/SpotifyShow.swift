import Foundation

/// The podcast an episode in the queue belongs to.
nonisolated struct SpotifyShow: Decodable, Sendable {
    let name: String
    let images: [SpotifyImage]?
}
