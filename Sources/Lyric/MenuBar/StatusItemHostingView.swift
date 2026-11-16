import SwiftUI

/// Hosts the SwiftUI menu bar label inside the status item's button.
///
/// It reports intrinsic size changes so the status item can follow its content, accepts the
/// first click so inline controls work while Lyric is not the active app, and forwards
/// right-clicks (quick menu) and scrolling (volume).
final class StatusItemHostingView<Content: View>: NSHostingView<Content> {
    var onIntrinsicSizeChange: ((NSSize) -> Void)?
    var onRightClick: ((NSEvent) -> Void)?
    var onScroll: ((NSEvent) -> Void)?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        onIntrinsicSizeChange?(intrinsicContentSize)
    }

    override func rightMouseDown(with event: NSEvent) {
        if let onRightClick {
            onRightClick(event)
        } else {
            super.rightMouseDown(with: event)
        }
    }

    override func scrollWheel(with event: NSEvent) {
        if let onScroll {
            onScroll(event)
        } else {
            super.scrollWheel(with: event)
        }
    }
}
