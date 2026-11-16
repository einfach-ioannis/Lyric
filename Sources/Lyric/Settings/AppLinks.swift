import Foundation

/// External pages linked from Settings. The literals are known-valid URLs.
enum AppLinks {
    static let github = URL(string: "https://github.com/einfach-ioannis/Lyric")!
    static let issues = URL(string: "https://github.com/einfach-ioannis/Lyric/issues")!
    static let lrclib = URL(string: "https://lrclib.net")!
    static let spotifyDashboard = URL(string: "https://developer.spotify.com/dashboard")!
    static let spotifyRedirectURI = "lyric://spotify-callback"
}
