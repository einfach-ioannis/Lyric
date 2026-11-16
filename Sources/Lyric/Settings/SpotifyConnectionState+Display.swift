import Foundation

extension SpotifyConnectionState {
    var isConnected: Bool {
        if case .connected = self { true } else { false }
    }

    var isFailure: Bool {
        if case .failed = self { true } else { false }
    }

    /// The status line shown in Settings.
    var statusText: String {
        switch self {
        case .notConfigured: String(localized: "Not configured")
        case .disconnected: String(localized: "Not connected")
        case .connecting: String(localized: "Connecting…")
        case .connected(let displayName): String(localized: "Connected as \(displayName)")
        case .failed(let message): message
        }
    }
}
