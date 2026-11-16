import AppKit
import Observation
import OSLog

final class AppDelegate: NSObject, NSApplicationDelegate {
    let nowPlaying = NowPlayingController()
    let library = LibraryController()
    let settings = AppSettings()

    private var statusItemController: StatusItemController?
    private var lockScreen: LockScreenController?
    private let onboarding = OnboardingWindowController()
    private var trackObservation: Task<Void, Never>?
    private var shuffleObservation: Task<Void, Never>?

    private let logger = Logger(subsystem: "lyric.einfach.de", category: "URL")

    /// Registers for `lyric://` links before launch completes, so the Spotify login redirect
    /// reaches Lyric directly instead of depending on SwiftUI's scene-based URL routing.
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        SettingsWindowController.shared.configure(settings: settings, library: library)
        statusItemController = StatusItemController(nowPlaying: nowPlaying, library: library, settings: settings)
        nowPlaying.start()
        observeTrackChanges()

        let lockScreen = LockScreenController(nowPlaying: nowPlaying, settings: settings)
        lockScreen.start()
        self.lockScreen = lockScreen

        if !settings.hasCompletedOnboarding {
            onboarding.show(nowPlaying: nowPlaying, library: library, settings: settings)
        }

        #if DEBUG
        if CommandLine.arguments.contains("--onboarding") {
            onboarding.show(nowPlaying: nowPlaying, library: library, settings: settings)
        }
        if CommandLine.arguments.contains("--settings") {
            SettingsWindowController.shared.show()
        }
        if CommandLine.arguments.contains("--preview-lock-screen") {
            Task {
                try? await Task.sleep(for: .seconds(2))
                lockScreen.preview()
            }
        }
        if CommandLine.arguments.contains("--show-popover") {
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                statusItemController?.togglePopover()
            }
        }
        #endif
    }

    /// Opening Lyric again from Finder or Launchpad shows the player instead of doing nothing.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusItemController?.togglePopover()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        trackObservation?.cancel()
        shuffleObservation?.cancel()
    }

    @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let text = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: text),
              url.scheme?.lowercased() == "lyric"
        else {
            logger.error("Ignored an unexpected URL event")
            return
        }
        logger.notice("Received \(url.host() ?? "", privacy: .public) callback")
        library.handleCallback(url)
    }

    /// Keeps the library (favorite state, Up Next) in step with the song that is playing.
    private func observeTrackChanges() {
        let tracks = Observations { [nowPlaying] in nowPlaying.track }
        trackObservation = Task { [library] in
            for await track in tracks {
                library.trackDidChange(track)
            }
        }

        // Switching shuffle reorders what comes next, so reload Up Next when it changes.
        let shuffles = Observations { [nowPlaying] in nowPlaying.isShuffling }
        shuffleObservation = Task { [library] in
            var previous: Bool??
            for await isShuffling in shuffles {
                if let previous, previous != nil, isShuffling != nil, previous != isShuffling {
                    library.refreshUpNext()
                }
                previous = .some(isShuffling)
            }
        }
    }
}
