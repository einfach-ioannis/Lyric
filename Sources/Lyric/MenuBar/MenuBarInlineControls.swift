import SwiftUI

/// Previous, play/pause and next, clickable directly in the menu bar.
struct MenuBarInlineControls: View {
    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        HStack(spacing: Theme.Spacing.hairline) {
            Button("Previous Track", systemImage: "backward.fill", action: nowPlaying.previousTrack)

            Button(
                nowPlaying.isPlaying ? LocalizedStringKey("Pause") : "Play",
                systemImage: nowPlaying.isPlaying ? "pause.fill" : "play.fill",
                action: nowPlaying.togglePlayPause
            )
            .contentTransition(.symbolEffect(.replace))

            Button("Next Track", systemImage: "forward.fill", action: nowPlaying.nextTrack)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(MenuBarControlButtonStyle())
    }
}
