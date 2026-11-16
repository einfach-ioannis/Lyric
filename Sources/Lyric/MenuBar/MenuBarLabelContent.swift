import SwiftUI

/// The visual part of the menu bar item for each `MenuBarDisplay` style.
struct MenuBarLabelContent: View {
    let display: MenuBarDisplay

    @Environment(NowPlayingController.self) private var nowPlaying
    @Environment(AppSettings.self) private var settings

    var body: some View {
        HStack(spacing: Theme.Spacing.compact) {
            if nowPlaying.track != nil, settings.hidesWhenPaused, nowPlaying.isPausedLong {
                // Long pauses reduce the item to just the cover, at its normal size.
                MenuBarArtwork(size: Theme.MenuBar.largeArtworkSize)
            } else if let track = nowPlaying.track {
                switch display {
                case .iconOnly:
                    MenuBarLevelMeter()
                case .artworkOnly:
                    MenuBarArtwork(size: Theme.MenuBar.largeArtworkSize)
                        .help("\(track.title) — \(track.artist)")
                        .accessibilityLabel("\(track.title) by \(track.artist)")
                case .title:
                    MenuBarLevelMeter()
                    Text(track.title.truncated())
                case .artworkAndArtist:
                    MenuBarArtwork()
                    Text("\(track.artist) — \(track.title)".truncated())
                case .lyrics:
                    MenuBarArtwork()
                    MenuBarLyricText(text: lyricOrTitle(for: track).truncated())
                case .inlineControls:
                    Text(track.title.truncated())
                }
            } else {
                Image(systemName: "music.note")
            }
        }
    }

    private func lyricOrTitle(for track: Track) -> String {
        guard let line = nowPlaying.currentLyricLine, !line.isBreak else { return track.title }
        return line.text
    }
}
