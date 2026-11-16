import Foundation

/// Decides whether a search result is the same song as the one playing.
///
/// Streaming services and lyrics databases often list slightly different cuts of a song
/// (radio edit vs. album version), so an exact title and artist match tolerates a larger
/// length difference than a fuzzy one.
nonisolated enum LyricsMatcher {
    static let looseTolerance: TimeInterval = 8
    static let exactMatchTolerance: TimeInterval = 20

    static func accepts(title: String?, artist: String?, durationDistance: TimeInterval, for track: Track) -> Bool {
        if durationDistance < looseTolerance {
            return true
        }
        guard durationDistance < exactMatchTolerance, let title, let artist else { return false }
        let titleMatches = normalized(title) == normalized(track.title)
            || normalized(title) == normalized(TitleCleaner.clean(track.title))
        let artistMatches = normalized(track.artist).contains(normalized(artist))
            || normalized(artist).contains(normalized(track.artist))
        return titleMatches && artistMatches
    }

    private static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
