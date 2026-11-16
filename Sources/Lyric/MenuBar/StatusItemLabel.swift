import SwiftUI

/// The SwiftUI content of the menu bar item. Clicking anywhere outside the inline
/// controls toggles the popover.
struct StatusItemLabel: View {
    let onToggle: () -> Void

    @Environment(NowPlayingController.self) private var nowPlaying
    @Environment(AppSettings.self) private var settings
    @Environment(StatusItemState.self) private var itemState

    private var showsInlineControls: Bool {
        settings.menuBarDisplay == .inlineControls && nowPlaying.track != nil
            && !(settings.hidesWhenPaused && !nowPlaying.isPlaying)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.compact) {
            if showsInlineControls {
                MenuBarInlineControls()
            }

            Button(action: onToggle) {
                MenuBarLabelContent(display: settings.menuBarDisplay)
                    .frame(maxHeight: .infinity)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Lyric")
            .accessibilityValue(accessibilitySummary)
            .accessibilityHint("Shows the player")
        }
        .padding(.horizontal, Theme.MenuBar.horizontalPadding)
        .frame(minWidth: Theme.MenuBar.minimumWidth)
        .frame(height: Theme.MenuBar.highlightHeight)
        .background {
            if itemState.isPopoverShown {
                Capsule()
                    .fill(.quaternary)
            }
        }
        .frame(maxHeight: .infinity)
        .fixedSize(horizontal: true, vertical: false)
        .foregroundStyle(.primary)
        .font(.body)
        .lineLimit(1)
    }

    private var accessibilitySummary: String {
        guard let track = nowPlaying.track else { return String(localized: "Nothing playing") }
        return String(localized: "\(track.title) by \(track.artist)")
    }
}
