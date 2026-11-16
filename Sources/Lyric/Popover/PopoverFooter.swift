import SwiftUI

struct PopoverFooter: View {
    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        HStack(spacing: Theme.Spacing.regular) {
            if nowPlaying.volume != nil {
                VolumeSlider()
            } else {
                Spacer()
            }

            OpenSettingsButton()
                .labelStyle(.iconOnly)
                .help("Settings")
            Button("Quit Lyric", systemImage: "power", action: quit)
                .labelStyle(.iconOnly)
                .help("Quit Lyric")
        }
        .buttonStyle(.borderless)
        .font(.callout)
        .foregroundStyle(.white.opacity(0.6))
        .padding(.horizontal, 22)
        .padding(.vertical, Theme.Spacing.regular)
    }

    private func quit() {
        NSApp.terminate(nil)
    }
}
