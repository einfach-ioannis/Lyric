import SwiftUI

/// Shuffle · previous · play/pause · next · repeat.
struct PopoverTransportRow: View {
    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        HStack {
            PlaybackModeButton(
                title: "Shuffle",
                systemImage: "shuffle",
                isOn: nowPlaying.isShuffling,
                action: nowPlaying.toggleShuffle
            )

            Spacer()

            Button("Previous Track", systemImage: "backward.fill", action: nowPlaying.previousTrack)
                .keyboardShortcut(.leftArrow, modifiers: [])
                .font(.system(size: 26))
                .buttonStyle(TransportButtonStyle())

            Spacer()

            PlayPauseButton()

            Spacer()

            Button("Next Track", systemImage: "forward.fill", action: nowPlaying.nextTrack)
                .keyboardShortcut(.rightArrow, modifiers: [])
                .font(.system(size: 26))
                .buttonStyle(TransportButtonStyle())

            Spacer()

            PlaybackModeButton(
                title: "Repeat",
                systemImage: "repeat",
                isOn: nowPlaying.isRepeating,
                action: nowPlaying.toggleRepeat
            )
        }
        .labelStyle(.iconOnly)
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Spacing.compact)
    }
}
