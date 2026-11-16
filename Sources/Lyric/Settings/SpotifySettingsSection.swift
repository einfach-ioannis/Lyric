import SwiftUI

/// Spotify connection: status first, then the Client ID and one-time setup steps.
struct SpotifySettingsSection: View {
    @Environment(LibraryController.self) private var library
    @State private var showsSetup = false

    private var canConnect: Bool {
        !library.spotifyClientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && library.spotifyConnection != .connecting
    }

    var body: some View {
        @Bindable var library = library
        let isConnected = library.spotifyConnection.isConnected

        Section {
            HStack(spacing: Theme.Spacing.medium) {
                Image(systemName: isConnected ? "checkmark.circle.fill" : "link.circle.fill")
                    .font(.title)
                    .foregroundStyle(isConnected ? Theme.Palette.spotify : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "Spotify")
                        .font(.headline)
                    Text(library.spotifyConnection.statusText)
                        .font(.callout)
                        .foregroundStyle(library.spotifyConnection.isFailure ? Color.red : Color.secondary)
                        .lineLimit(2)
                }
                Spacer()
                if isConnected {
                    Button("Disconnect", action: library.disconnectSpotify)
                } else {
                    Button("Connect", action: library.connectSpotify)
                        .buttonStyle(.borderedProminent)
                        .disabled(!canConnect)
                }
            }
            .padding(.vertical, Theme.Spacing.tight)
        } footer: {
            if !isConnected {
                Text("Connect Spotify to see Up Next, switch playlists and like songs from the menu bar.")
            }
        }

        Section {
            if isConnected {
                LabeledContent("Client ID", value: Self.masked(library.spotifyClientID))
            } else {
                TextField("Client ID", text: $library.spotifyClientID, prompt: Text("Paste your Client ID"))
                    .autocorrectionDisabled()
                SpotifyRedirectURIRow()
            }
        }

        if !isConnected {
            Section {
                DisclosureGroup("How to get a Client ID", isExpanded: $showsSetup) {
                    SpotifySetupSteps()
                        .padding(.vertical, Theme.Spacing.tight)
                }
            }
            .onAppear {
                showsSetup = library.spotifyClientID.isEmpty
            }
        }
    }

    /// Shows only the last four characters once connected.
    private static func masked(_ id: String) -> String {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 4 else { return trimmed }
        return String(repeating: "•", count: 8) + trimmed.suffix(4)
    }
}
