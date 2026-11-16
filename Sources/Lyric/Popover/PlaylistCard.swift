import SwiftUI

/// A playlist tile. Clicking plays it straight away; the context menu can show it in its app.
struct PlaylistCard: View {
    let playlist: PlaylistSummary

    @Environment(LibraryController.self) private var library
    @State private var isHovering = false

    var body: some View {
        Button(action: play) {
            HStack(spacing: Theme.Spacing.small) {
                artwork
                    .overlay {
                        if isHovering {
                            ZStack {
                                Color.black.opacity(0.35)
                                Image(systemName: "play.fill")
                                    .font(.callout)
                                    .foregroundStyle(.white)
                            }
                            .clipShape(.rect(cornerRadius: Theme.Radius.artworkSmall))
                            .transition(.opacity)
                        }
                    }

                VStack(alignment: .leading, spacing: 1) {
                    Text(playlist.name)
                        .font(.callout)
                        .bold()
                        .lineLimit(1)
                    if !playlist.detail.isEmpty {
                        Text(playlist.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Theme.Spacing.compact)
        }
        .buttonStyle(CardButtonStyle())
        .onHover { hovering in
            withAnimation(Theme.Motion.quick) { isHovering = hovering }
        }
        .contextMenu {
            Button("Play", systemImage: "play.fill", action: play)
            Button("Show in \(playlist.source.displayName)", systemImage: "arrow.up.forward.app") {
                library.reveal(playlist)
            }
        }
        .help(Text("Play \(playlist.name)"))
        .accessibilityHint(Text("Plays this playlist"))
    }

    @ViewBuilder
    private var artwork: some View {
        if playlist.isLikedSongs {
            LikedSongsArtwork(size: Theme.Popover.playlistArtworkSize)
        } else {
            RemoteArtwork(url: playlist.artworkURL, size: Theme.Popover.playlistArtworkSize, cornerRadius: Theme.Radius.artworkSmall)
        }
    }

    private func play() {
        library.play(playlist)
    }
}

/// A purple-to-blue gradient with a white heart, as Spotify draws Liked Songs.
struct LikedSongsArtwork: View {
    let size: Double

    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.27, green: 0.16, blue: 0.84), Color(red: 0.55, green: 0.75, blue: 0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.38))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: Theme.Radius.artworkSmall))
        .accessibilityHidden(true)
    }
}
