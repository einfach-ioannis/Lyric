import SwiftUI

struct PlaylistsGrid: View {
    @Environment(LibraryController.self) private var library

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.regular),
        GridItem(.flexible(), spacing: Theme.Spacing.regular),
    ]

    var body: some View {
        Group {
            if !library.playlists.isEmpty {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: Theme.Spacing.regular) {
                        ForEach(library.playlists) { playlist in
                            PlaylistCard(playlist: playlist)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.vertical, Theme.Spacing.regular)
                }
                .scrollIndicators(.never)
            } else if !library.spotifyConnection.isConnected {
                ContentUnavailableView {
                    Label("No Playlists", systemImage: "music.note.list")
                } description: {
                    Text("Connect Spotify in Settings to switch playlists from here.")
                } actions: {
                    OpenSettingsButton(title: "Open Settings")
                }
            } else {
                ContentUnavailableView(
                    "No Playlists",
                    systemImage: "music.note.list",
                    description: Text("Playlists you make or follow will appear here.")
                )
            }
        }
        .task {
            library.reloadPlaylists()
        }
    }
}
