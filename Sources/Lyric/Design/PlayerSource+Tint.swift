import SwiftUI

extension PlayerSource {
    /// The player's brand color, used for the small source dot in the popover.
    var tint: Color {
        switch self {
        case .appleMusic: Theme.Palette.appleMusic
        case .spotify: Theme.Palette.spotify
        }
    }
}
