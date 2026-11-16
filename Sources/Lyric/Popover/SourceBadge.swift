import SwiftUI

/// "Playing on Spotify" with a small dot in the player's brand color.
struct SourceBadge: View {
    let source: PlayerSource
    let isPlaying: Bool

    var body: some View {
        Label {
            if isPlaying {
                Text("Playing on \(source.displayName)")
            } else {
                Text("Paused on \(source.displayName)")
            }
        } icon: {
            Circle()
                .fill(source.tint)
                .frame(width: Theme.Popover.sourceDotSize, height: Theme.Popover.sourceDotSize)
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.55))
        .lineLimit(1)
    }
}
