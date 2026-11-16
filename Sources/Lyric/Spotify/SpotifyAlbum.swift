import Foundation

nonisolated struct SpotifyAlbum: Decodable, Sendable {
    let images: [SpotifyImage]?
}
