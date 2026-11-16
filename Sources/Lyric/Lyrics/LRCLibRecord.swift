import Foundation

/// A lyrics record from the LRCLIB API (https://lrclib.net/docs).
nonisolated struct LRCLibRecord: Decodable, Sendable {
    let trackName: String?
    let artistName: String?
    let duration: Double?
    let instrumental: Bool?
    let plainLyrics: String?
    let syncedLyrics: String?
}
