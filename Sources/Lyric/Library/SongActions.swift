import AppKit

/// Small things you can do with the current song: copy it, copy its lyrics, look it up.
enum SongActions {
    static func copyInfo(_ track: Track) {
        copy("\(track.title) — \(track.artist)")
    }

    static func copyLyrics(_ lyrics: Lyrics) {
        let text = lyrics.lines.map { $0.isBreak ? "" : $0.text }.joined(separator: "\n")
        copy(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Opens a web search for the song's lyrics.
    static func searchLyrics(for track: Track) {
        var components = URLComponents(string: "https://duckduckgo.com/")
        components?.queryItems = [URLQueryItem(name: "q", value: "\(track.artist) \(track.title) lyrics")]
        if let url = components?.url {
            NSWorkspace.shared.open(url)
        }
    }

    private static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
