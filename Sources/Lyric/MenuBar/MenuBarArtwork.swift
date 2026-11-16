import SwiftUI

/// The small rounded cover shown in the menu bar. Drawn flat (no shadow) so it sits on the
/// same baseline and visual weight as the system's own menu bar icons.
struct MenuBarArtwork: View {
    var size = Theme.MenuBar.artworkSize

    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        ZStack {
            if let image = nowPlaying.artwork {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.7))
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: Theme.Radius.artworkTiny))
        .accessibilityHidden(true)
    }
}
