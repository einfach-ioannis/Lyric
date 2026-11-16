import SwiftUI

@main
struct LyricApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The menu bar item and its popover are AppKit-owned (see `StatusItemController`),
        // so the only SwiftUI scene is Settings.
        Settings {
            SettingsView()
                .environment(appDelegate.settings)
                .environment(appDelegate.library)
        }
    }
}
