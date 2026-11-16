import SwiftUI

/// The fixed-height area under the tab picker.
struct PopoverTabContent: View {
    let tab: PopoverTab

    var body: some View {
        ZStack {
            switch tab {
            case .lyrics:
                LyricsPanel()
            case .upNext:
                UpNextList()
            case .playlists:
                PlaylistsGrid()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Theme.Popover.contentHeight)
    }
}
