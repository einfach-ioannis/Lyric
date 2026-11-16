import AppKit
import SwiftUI

/// Owns the Settings window, so it can be opened from AppKit (the right-click menu) as well
/// as from SwiftUI.
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?
    private var makeContent: (() -> AnyView)?

    /// Called once at launch with the shared models.
    func configure(settings: AppSettings, library: LibraryController) {
        makeContent = {
            AnyView(
                SettingsView()
                    .environment(settings)
                    .environment(library)
            )
        }
    }

    func show() {
        NSApp.activate()
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }
        guard let makeContent else { return }

        let controller = NSHostingController(rootView: makeContent())
        controller.sizingOptions = [.preferredContentSize]
        let window = NSWindow(contentViewController: controller)
        window.styleMask = [.titled, .closable]
        window.title = String(localized: "Lyric Settings")
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
        window.makeKeyAndOrderFront(nil)
    }
}
