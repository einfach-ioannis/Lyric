import SwiftUI

/// Closes the popover, brings Lyric forward and opens the Settings window.
struct OpenSettingsButton: View {
    var title: LocalizedStringKey = "Settings…"

    @Environment(\.popoverDismiss) private var dismissPopover

    var body: some View {
        Button(title, systemImage: "gearshape", action: open)
    }

    private func open() {
        dismissPopover?()
        SettingsWindowController.shared.show()
    }
}
