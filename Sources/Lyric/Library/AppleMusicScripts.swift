import Foundation

/// AppleScript sources and parsers for the Music library: favorites, playlists and Up Next.
nonisolated enum AppleMusicScripts {
    /// Separates fields inside one record.
    static let fieldSeparator: Character = "\u{1F}"
    /// Separates records.
    static let recordSeparator: Character = "\u{1E}"

    /// `favorited` replaced `loved` in macOS 14; the fallback covers older dictionaries.
    static let currentTrackFavorite = """
    with timeout of 2 seconds
        tell application "Music"
            set t to current track
            try
                return (favorited of t) as string
            end try
            try
                return (loved of t) as string
            end try
            return ""
        end tell
    end timeout
    """

    static func setCurrentTrackFavorite(_ favorite: Bool) -> String {
        """
        with timeout of 2 seconds
            tell application "Music"
                set t to current track
                try
                    set favorited of t to \(favorite)
                    return "ok"
                end try
                set loved of t to \(favorite)
                return "ok"
            end tell
        end timeout
        """
    }

    static let playlists = """
    with timeout of 2 seconds
        tell application "Music"
            set fieldSep to (character id 31)
            set recordSep to (character id 30)
            set resultText to ""
            repeat with p in (every user playlist whose special kind is none and smart is false)
                try
                    set playlistID to persistent ID of p
                    set playlistName to name of p
                    set songCount to count of tracks of p
                    set resultText to resultText & playlistID & fieldSep & playlistName & fieldSep & (songCount as string) & recordSep
                end try
            end repeat
            return resultText
        end tell
    end timeout
    """

    static func play(playlistID: String) -> String {
        """
        with timeout of 2 seconds
            tell application "Music" to play (first user playlist whose persistent ID is "\(escaped(playlistID))")
        end timeout
        """
    }

    static func reveal(playlistID: String) -> String {
        """
        with timeout of 2 seconds
            tell application "Music"
                reveal (first user playlist whose persistent ID is "\(escaped(playlistID))")
                activate
            end tell
        end timeout
        """
    }

    /// Music's real queue isn't scriptable, so this lists the tracks after the current one in its playlist.
    static func upNext(limit: Int) -> String {
        """
        with timeout of 2 seconds
            tell application "Music"
                set fieldSep to (character id 31)
                set recordSep to (character id 30)
                set resultText to ""
                set sourcePlaylist to current playlist
                set currentIndex to index of current track
                set trackCount to count of tracks of sourcePlaylist
                set lastIndex to currentIndex + \(max(limit, 0))
                if lastIndex > trackCount then set lastIndex to trackCount
                repeat with trackIndex from (currentIndex + 1) to lastIndex
                    try
                        set t to track trackIndex of sourcePlaylist
                        set resultText to resultText & (persistent ID of t) & fieldSep & (name of t) & fieldSep & (artist of t) & fieldSep & ((duration of t) as string) & recordSep
                    end try
                end repeat
                return resultText
            end tell
        end timeout
        """
    }

    static func parseFavorite(_ output: String?) -> Bool? {
        switch output?.lowercased() {
        case "true": true
        case "false": false
        default: nil
        }
    }

    static func parsePlaylists(_ output: String?) -> [PlaylistSummary] {
        records(in: output).compactMap { fields in
            guard fields.count >= 3, !fields[0].isEmpty, !fields[1].isEmpty else { return nil }
            let count = Int(fields[2]) ?? 0
            return PlaylistSummary(
                id: fields[0],
                name: fields[1],
                detail: count == 1 ? String(localized: "1 song") : String(localized: "\(count) songs"),
                artworkURL: nil,
                source: .appleMusic
            )
        }
    }

    static func parseQueue(_ output: String?) -> [QueueItem] {
        records(in: output).compactMap { fields in
            guard fields.count >= 4, !fields[0].isEmpty, !fields[1].isEmpty else { return nil }
            return QueueItem(
                id: fields[0],
                title: fields[1],
                artist: fields[2],
                duration: PlayerScripts.number(from: fields[3]),
                artworkURL: nil
            )
        }
    }

    /// Escapes a value for use inside an AppleScript string literal.
    static func escaped(_ text: String) -> String {
        text.replacing("\\", with: "\\\\").replacing("\"", with: "\\\"")
    }

    private static func records(in output: String?) -> [[String]] {
        guard let output, !output.isEmpty else { return [] }
        return output
            .split(separator: recordSeparator)
            .map { $0.split(separator: fieldSeparator, omittingEmptySubsequences: false).map(String.init) }
    }
}
