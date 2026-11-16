import Foundation

nonisolated enum SpotifyConnectionState: Equatable, Sendable {
    /// No Client ID saved yet.
    case notConfigured
    case disconnected
    case connecting
    case connected(displayName: String)
    case failed(message: String)
}
