import Foundation

/// A music app Lyric can read from and control.
nonisolated enum PlayerSource: String, Sendable, CaseIterable, Identifiable {
    case appleMusic
    case spotify

    var id: Self { self }

    var bundleIdentifier: String {
        switch self {
        case .appleMusic: "com.apple.Music"
        case .spotify: "com.spotify.client"
        }
    }

    var displayName: String {
        switch self {
        case .appleMusic: "Music"
        case .spotify: "Spotify"
        }
    }

    /// The application name used inside AppleScript `tell` blocks.
    var scriptingName: String {
        switch self {
        case .appleMusic: "Music"
        case .spotify: "Spotify"
        }
    }

    /// Distributed notification the app posts whenever playback changes.
    var playbackNotification: Notification.Name {
        switch self {
        case .appleMusic: Notification.Name("com.apple.Music.playerInfo")
        case .spotify: Notification.Name("com.spotify.client.PlaybackStateChanged")
        }
    }
}
