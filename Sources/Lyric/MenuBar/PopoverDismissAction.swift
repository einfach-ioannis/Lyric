import Foundation

/// Lets SwiftUI views inside the popover close it, e.g. before opening Settings.
struct PopoverDismissAction {
    weak var controller: StatusItemController?

    func callAsFunction() {
        controller?.closePopover()
    }
}
