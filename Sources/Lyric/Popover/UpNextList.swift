import SwiftUI

struct UpNextList: View {
    @Environment(LibraryController.self) private var library
    @Environment(NowPlayingController.self) private var nowPlaying

    private var needsSpotifyConnection: Bool {
        nowPlaying.track?.source == .spotify && !library.spotifyConnection.isConnected
    }

    var body: some View {
        content
            // The queue can change in the player (shuffle, songs added); reload on open.
            .task { library.refreshUpNext() }
    }

    @ViewBuilder
    private var content: some View {
        if !library.upNext.isEmpty {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.hairline) {
                    ForEach(library.upNext) { item in
                        QueueRow(item: item)
                    }
                }
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.regular)
            }
            .scrollIndicators(.never)
        } else if needsSpotifyConnection {
            ContentUnavailableView {
                Label("Up Next", systemImage: "list.bullet")
            } description: {
                Text("Connect Spotify in Settings to see Up Next.")
            } actions: {
                OpenSettingsButton(title: "Open Settings")
            }
        } else {
            ContentUnavailableView(
                "Nothing Up Next",
                systemImage: "list.bullet",
                description: Text("Songs queued after this one will appear here.")
            )
        }
    }
}
