import SwiftUI

/// The large white play/pause disc in the middle of the transport row.
struct PlayPauseButton: View {
    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        Button(
            nowPlaying.isPlaying ? LocalizedStringKey("Pause") : "Play",
            systemImage: nowPlaying.isPlaying ? "pause.fill" : "play.fill",
            action: nowPlaying.togglePlayPause
        )
        .labelStyle(.iconOnly)
        .contentTransition(.symbolEffect(.replace))
        .buttonStyle(PlayPauseButtonStyle())
        .keyboardShortcut(.space, modifiers: [])
    }
}
