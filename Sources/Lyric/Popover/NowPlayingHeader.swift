import SwiftUI

struct NowPlayingHeader: View {
    let track: Track

    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        HStack(spacing: 14) {
            Button(action: nowPlaying.openSourceApp) {
                ArtworkView(image: nowPlaying.artwork, size: Theme.Popover.artworkSize, cornerRadius: 12)
            }
            .buttonStyle(.plain)
            .help("Open in \(track.source.displayName)")
            .accessibilityLabel("Open in \(track.source.displayName)")

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                Text(track.artist)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
                SourceBadge(source: track.source, isPlaying: nowPlaying.isPlaying)
                    .padding(.top, 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentTransition(.opacity)
            .contentShape(.rect)
            .contextMenu {
                Button("Copy Song and Artist", systemImage: "doc.on.doc") {
                    SongActions.copyInfo(track)
                }
                if let lyrics = nowPlaying.loadedLyrics {
                    Button("Copy Lyrics", systemImage: "quote.bubble") {
                        SongActions.copyLyrics(lyrics)
                    }
                }
                Button("Search Lyrics on the Web", systemImage: "magnifyingglass") {
                    SongActions.searchLyrics(for: track)
                }
            }

            FavoriteButton()
        }
        .animation(.smooth, value: track)
    }
}
