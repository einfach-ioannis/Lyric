import SwiftUI

struct LyricsPanel: View {
    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        ZStack {
            switch nowPlaying.lyrics {
            case .loading:
                ProgressView()
                    .controlSize(.small)
            case .loaded(let lyrics):
                LyricsScrollView(lyrics: lyrics, currentIndex: nowPlaying.currentLyricIndex)
            case .instrumental:
                ContentUnavailableView("Instrumental", systemImage: "pianokeys", description: Text("Sit back and enjoy the music."))
            case .idle, .unavailable:
                ContentUnavailableView {
                    Label("No Lyrics", systemImage: "quote.bubble")
                } description: {
                    Text("Lyrics for this song aren’t available yet.")
                } actions: {
                    if let track = nowPlaying.track {
                        Button("Search the Web") {
                            SongActions.searchLyrics(for: track)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Theme.Popover.contentHeight)
        .transition(.opacity)
    }
}
