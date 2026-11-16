import Foundation

/// The sections below the transport controls in the popover.
enum PopoverTab: String, CaseIterable, Identifiable {
    case lyrics
    case upNext
    case playlists

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .lyrics: "Lyrics"
        case .upNext: "Up Next"
        case .playlists: "Playlists"
        }
    }
}
