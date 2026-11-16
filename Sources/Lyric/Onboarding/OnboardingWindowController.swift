import AppKit
import SwiftUI

/// Shows the welcome window on first launch.
final class OnboardingWindowController {
    private var window: NSWindow?

    func show(nowPlaying: NowPlayingController, library: LibraryController, settings: AppSettings) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let rootView = OnboardingView(onFinish: { [weak self] in self?.finish(settings: settings) })
            .environment(nowPlaying)
            .environment(library)
            .environment(settings)

        let window = NSWindow(contentViewController: NSHostingController(rootView: rootView))
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.title = String(localized: "Welcome to Lyric")
        window.center()
        self.window = window

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func finish(settings: AppSettings) {
        settings.hasCompletedOnboarding = true
        window?.close()
        window = nil
    }
}
