import SwiftUI

extension EnvironmentValues {
    /// Closes the menu bar popover. `nil` outside the popover, such as in Settings.
    @Entry var popoverDismiss: PopoverDismissAction?
}
