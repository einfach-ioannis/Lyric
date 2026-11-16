import SwiftUI

/// The player's volume (0...100). Mirrors the player and only writes back real changes.
struct VolumeSlider: View {
    @Environment(NowPlayingController.self) private var nowPlaying
    @State private var level = 0.0

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Image(systemName: "speaker.wave.3.fill", variableValue: level / 100)
                .accessibilityHidden(true)

            Slider(value: $level, in: 0...100) {
                Text("Volume")
            }
            .labelsHidden()
            .controlSize(.small)
            .tint(.white)
        }
        .onChange(of: nowPlaying.volume, initial: true) { _, newVolume in
            sync(to: newVolume)
        }
        .onChange(of: level) { _, newLevel in
            apply(newLevel)
        }
    }

    private func sync(to volume: Double?) {
        if let volume {
            level = volume
        }
    }

    private func apply(_ newLevel: Double) {
        guard let current = nowPlaying.volume, abs(current - newLevel) >= 0.5 else { return }
        nowPlaying.setVolume(newLevel)
    }
}
