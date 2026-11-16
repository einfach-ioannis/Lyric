import SwiftUI

/// The animated level meter: the only element in the menu bar that uses the artwork accent.
struct MenuBarLevelMeter: View {
    @Environment(NowPlayingController.self) private var nowPlaying

    /// `.white` is the controller's "no accent yet" value, which would vanish in a light menu bar.
    private var color: Color {
        nowPlaying.accent == .white ? .primary : nowPlaying.accent
    }

    var body: some View {
        EqualizerBars(isPlaying: nowPlaying.isPlaying, color: color, height: Theme.MenuBar.meterHeight)
    }
}
