import SwiftUI

/// Spotify connection: Client ID entry, status, and connect / disconnect.
struct SpotifySettingsSection: View {
    @Environment(LibraryController.self) private var library

    private var canConnect: Bool {
        !library.spotifyClientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && library.spotifyConnection != .connecting
    }

    var body: some View {
        @Bindable var library = library

        Section("Spotify") {
            SpotifySetupSteps()

            SpotifyRedirectURIRow()

            TextField("Client ID", text: $library.spotifyClientID)
                .autocorrectionDisabled()
                .monospaced()

            LabeledContent("Status") {
                Text(library.spotifyConnection.statusText)
                    .foregroundStyle(library.spotifyConnection.isFailure ? Color.red : Color.secondary)
            }

            HStack {
                Spacer()
                if library.spotifyConnection.isConnected {
                    Button("Disconnect", action: library.disconnectSpotify)
                } else {
                    Button("Connect", action: library.connectSpotify)
                        .disabled(!canConnect)
                }
            }
        }
    }
}
