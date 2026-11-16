import Foundation

nonisolated struct ITunesSearchResponse: Decodable, Sendable {
    nonisolated struct Result: Decodable, Sendable {
        let artworkUrl100: String?
    }

    let results: [Result]
}
