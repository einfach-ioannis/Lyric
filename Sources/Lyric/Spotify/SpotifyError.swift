import Foundation

/// Everything that can go wrong talking to Spotify, with messages fit for the Settings window.
nonisolated enum SpotifyError: LocalizedError, Equatable, Sendable {
    case notConfigured
    case notSignedIn
    case sessionExpired
    case accessDenied
    case stateMismatch
    case invalidCallback
    case authorizationFailed(code: String, description: String?)
    case rateLimited
    case http(status: Int)
    case invalidRequest
    case invalidResponse
    case network(String)
    case storage

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            String(localized: "Add your Spotify Client ID in Settings first.")
        case .notSignedIn:
            String(localized: "Connect Spotify in Settings.")
        case .sessionExpired:
            String(localized: "Your Spotify session expired. Connect again in Settings.")
        case .accessDenied:
            String(localized: "Spotify access was declined.")
        case .stateMismatch:
            String(localized: "The Spotify login didn’t match this request. Try connecting again.")
        case .invalidCallback:
            String(localized: "Spotify returned an unexpected login response. Try connecting again.")
        case .authorizationFailed(let code, let description):
            switch code {
            case "invalid_client":
                String(localized: "Spotify didn’t accept the Client ID. Check it, and add lyric://spotify-callback as a Redirect URI of your Spotify app.")
            case "invalid_grant":
                String(localized: "The Spotify login expired. Try connecting again.")
            default:
                String(localized: "Spotify login failed: \(description ?? code)")
            }
        case .rateLimited:
            String(localized: "Spotify is busy right now. Try again in a moment.")
        case .http(403):
            String(localized: "Spotify refused access. Make sure your account is listed under Users in your app on the Spotify Developer Dashboard.")
        case .http(let status):
            String(localized: "Spotify returned an error (\(status)).")
        case .invalidRequest:
            String(localized: "Lyric couldn’t build the Spotify request.")
        case .invalidResponse:
            String(localized: "Spotify sent a response Lyric couldn’t read.")
        case .network(let detail):
            String(localized: "Couldn’t reach Spotify: \(detail)")
        case .storage:
            String(localized: "Couldn’t save the Spotify login.")
        }
    }
}
