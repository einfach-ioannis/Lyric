import Foundation

/// AppleScript sources and parsers for each supported player.
nonisolated enum PlayerScripts {
    /// Fields are separated by the ASCII unit separator so titles may contain any punctuation.
    static let separator: Character = "\u{1F}"

    static func status(for source: PlayerSource) -> String {
        let durationExpression = switch source {
        case .appleMusic: "duration of t"
        case .spotify: "(duration of t) / 1000"
        }
        let identifierExpression = switch source {
        case .appleMusic: "persistent ID of t"
        case .spotify: "id of t"
        }
        let artworkExpression = switch source {
        case .appleMusic: "\"\""
        case .spotify: "artwork url of t"
        }
        let shuffleExpression = switch source {
        case .appleMusic: "shuffle enabled"
        case .spotify: "shuffling"
        }
        let repeatExpression = switch source {
        case .appleMusic: "song repeat"
        case .spotify: "repeating"
        }

        return """
        with timeout of 2 seconds
            tell application "\(source.scriptingName)"
                set sep to (character id 31)
                set stateText to player state as string
                if stateText is "stopped" then return "stopped"
                set t to current track
                set trackName to ""
                set trackArtist to ""
                set trackAlbum to ""
                set trackDuration to 0
                set trackID to ""
                set trackArtwork to ""
                try
                    set trackName to name of t
                end try
                try
                    set trackArtist to artist of t
                end try
                try
                    set trackAlbum to album of t
                end try
                try
                    set trackDuration to \(durationExpression)
                end try
                try
                    set trackID to \(identifierExpression)
                end try
                try
                    set trackArtwork to \(artworkExpression)
                end try
                set positionValue to 0
                try
                    set positionValue to player position
                end try
                set shuffleText to ""
                set repeatText to ""
                set volumeText to ""
                try
                    set shuffleText to (\(shuffleExpression)) as string
                end try
                try
                    set repeatText to (\(repeatExpression)) as string
                end try
                try
                    set volumeText to (sound volume) as string
                end try
                return stateText & sep & trackName & sep & trackArtist & sep & trackAlbum & sep & (trackDuration as string) & sep & (positionValue as string) & sep & trackID & sep & trackArtwork & sep & shuffleText & sep & repeatText & sep & volumeText
            end tell
        end timeout
        """
    }

    static func command(_ command: PlayerCommand, for source: PlayerSource) -> String {
        """
        with timeout of 2 seconds
            tell application "\(source.scriptingName)" to \(command.scriptBody(for: source))
        end timeout
        """
    }

    static let musicArtwork = """
    with timeout of 3 seconds
        tell application "Music"
            try
                return raw data of artwork 1 of current track
            end try
        end tell
    end timeout
    """

    static func parseStatus(_ output: String?, source: PlayerSource) -> PlaybackSnapshot? {
        guard let output, output != "stopped" else { return nil }
        let fields = output.split(separator: separator, omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 8, !fields[1].isEmpty else { return nil }

        let title = fields[1]
        let artist = fields[2]
        let album = fields[3]
        let identifier = fields[6].isEmpty ? "\(source.rawValue):\(title)|\(artist)|\(album)" : "\(source.rawValue):\(fields[6])"

        let track = Track(
            id: identifier,
            title: title,
            artist: artist,
            album: album,
            duration: number(from: fields[4]),
            source: source,
            artworkURL: URL(string: fields[7])
        )
        // Shuffle, repeat and volume were appended later; older output simply lacks them.
        let extras = fields.dropFirst(8)
        let shuffleField = extras.first
        let repeatField = extras.dropFirst().first
        let volumeField = extras.dropFirst(2).first

        return PlaybackSnapshot(
            track: track,
            isPlaying: fields[0] == "playing",
            position: number(from: fields[5]),
            isShuffling: shuffleField.flatMap(flag(from:)),
            isRepeating: repeatField.flatMap(repeatFlag(from:)),
            volume: volumeField.flatMap(optionalNumber(from:)).map(VolumeLevel.clamped)
        )
    }

    /// AppleScript formats reals with the user's decimal separator, so accept both.
    static func number(from text: String) -> Double {
        optionalNumber(from: text) ?? 0
    }

    static func optionalNumber(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed.replacing(",", with: "."))
    }

    private static func flag(from text: String) -> Bool? {
        switch text.lowercased() {
        case "true": true
        case "false": false
        default: nil
        }
    }

    /// Spotify reports a boolean; Music reports `off`, `one` or `all`, or the raw
    /// `«constant ****kRpO»` form when its terminology isn't loaded.
    private static func repeatFlag(from text: String) -> Bool? {
        switch text.lowercased() {
        case "true", "one", "all": return true
        case "false", "off": return false
        default:
            if text.contains("kRpO") { return false }
            if text.contains("kRp1") || text.contains("kAll") { return true }
            return nil
        }
    }
}
