import SwiftUI

struct PlayerPopoverView: View {
    @Environment(NowPlayingController.self) private var nowPlaying
    @AppStorage("popoverTab") private var tab = PopoverTab.lyrics

    var body: some View {
        VStack(spacing: 0) {
            if nowPlaying.needsAutomationPermission {
                PermissionPrompt()
            } else if let track = nowPlaying.track {
                NowPlayingSection(track: track, tab: $tab)
                PopoverTabContent(tab: tab)
            } else {
                ContentUnavailableView(
                    "Nothing Playing",
                    systemImage: "music.note",
                    description: Text("Play something in Music or Spotify.")
                )
                .padding(.vertical, Theme.Spacing.extraLarge)
            }

            PopoverFooter()
        }
        .frame(width: Theme.Popover.width)
        .foregroundStyle(.white)
        .background {
            // The same tinted glass as the lock screen card.
            ZStack {
                ArtworkBackdrop(image: nowPlaying.artwork, accent: nowPlaying.accent)
                Color.black.opacity(0.12)
            }
            // Reach into the popover arrow so it carries the tint too.
            .ignoresSafeArea()
        }
        .task {
            nowPlaying.refresh()
        }
    }
}
