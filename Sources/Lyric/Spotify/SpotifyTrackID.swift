import Foundation

/// Converts Lyric's Spotify track IDs into Web API IDs.
nonisolated enum SpotifyTrackID {
    /// `spotify:spotify:track:6YJrz5WxB02vFvZZoZFK9t` → `6YJrz5WxB02vFvZZoZFK9t`.
    ///
    /// Returns `nil` for local files, episodes, ads and title-based fallback IDs.
    static func bareID(fromTrackID trackID: String) -> String? {
        let parts = trackID.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count >= 3, parts[parts.count - 2] == "track", let last = parts.last, !last.isEmpty,
              last.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) })
        else { return nil }
        return String(last)
    }
}
