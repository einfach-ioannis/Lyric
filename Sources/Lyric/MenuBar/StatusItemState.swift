import Observation

/// UI state of the menu bar item that the SwiftUI label draws itself.
@Observable
final class StatusItemState {
    /// Lyric draws its own highlight, centred on the label, because the system highlight
    /// has a minimum width and sits off-centre on very narrow items such as cover-art-only.
    var isPopoverShown = false
}
