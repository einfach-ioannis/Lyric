import Foundation

/// The saved Spotify session, stored as JSON in a private file in Application Support.
nonisolated struct SpotifyTokens: Codable, Equatable, Sendable {
    var accessToken: String
    var refreshToken: String
    var expiry: Date
    var displayName: String
    var userID: String
    /// Refresh tokens are bound to the app that issued them.
    var clientID: String

    /// True when the access token is expired or about to be, leaving a minute of slack.
    func needsRefresh(at date: Date = .now) -> Bool {
        expiry.timeIntervalSince(date) < 60
    }
}
