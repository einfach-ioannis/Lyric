import AppKit
import SwiftUI

/// Shows the large player with lyrics while the Mac is locked.
///
/// The card lives in its own small borderless panel beside the system's clock and password
/// field (never on top of them), placed in a SkyLight space that draws above the lock screen.
final class LockScreenController {
    /// The running instance, so Settings can show a preview.
    private(set) static weak var shared: LockScreenController?
    private let nowPlaying: NowPlayingController
    private let settings: AppSettings

    private var space: LockScreenSpace?
    private var panel: NSPanel?
    private var isLocked = false
    private var observers: [(NotificationCenter, any NSObjectProtocol)] = []
    private var stateObservation: Task<Void, Never>?
    private var previewTask: Task<Void, Never>?

    init(nowPlaying: NowPlayingController, settings: AppSettings) {
        self.nowPlaying = nowPlaying
        self.settings = settings
    }

    func start() {
        Self.shared = self
        guard LockScreenSpace.isAvailable, observers.isEmpty else { return }

        let distributed = DistributedNotificationCenter.default()
        observe(distributed, Notification.Name("com.apple.screenIsLocked")) { $0.setLocked(true) }
        observe(distributed, Notification.Name("com.apple.screenIsUnlocked")) { $0.setLocked(false) }

        let workspace = NSWorkspace.shared.notificationCenter
        // Waking the display can rebuild the lock screen; put the card back on top.
        // (Esc on the lock screen is macOS turning the display off; this brings the card back.)
        observe(workspace, NSWorkspace.screensDidWakeNotification) { $0.reattach() }
        observe(workspace, NSWorkspace.sessionDidBecomeActiveNotification) { $0.setLocked(false) }
        observe(NotificationCenter.default, NSApplication.didChangeScreenParametersNotification) { $0.reposition() }

        // Show or hide as music starts and stops, or the setting changes, while locked.
        let changes = Observations { [nowPlaying, settings] in
            (
                nowPlaying.track != nil,
                settings.showsLockScreenPlayer,
                settings.lockScreenPlacement,
                settings.lockScreenHeight,
                settings.lockScreenShowsLyrics
            )
        }
        stateObservation = Task { [weak self] in
            for await _ in changes {
                self?.update()
            }
        }
    }

    /// Shows the card on the desktop for a few seconds, so its position can be checked.
    func preview() {
        let panel = panel ?? makePanel()
        self.panel = panel
        reposition()
        panel.alphaValue = 1
        panel.orderFrontRegardless()
        previewTask?.cancel()
        previewTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled, let self, !self.isLocked else { return }
            self.hide()
        }
    }

    /// Puts the card back after the display slept, since the lock screen is redrawn on wake.
    private func reattach() {
        guard isLocked else { return }
        hide()
        update()
    }

    // MARK: State

    private func setLocked(_ locked: Bool) {
        isLocked = locked
        update()
    }

    private func update() {
        if !isLocked, previewTask != nil, panel?.isVisible == true {
            reposition()
            return
        }
        let shouldShow = isLocked && settings.showsLockScreenPlayer && nowPlaying.track != nil
        if shouldShow {
            show()
        } else {
            hide()
        }
    }

    private func show() {
        let panel = panel ?? makePanel()
        self.panel = panel
        reposition()
        panel.orderFrontRegardless()

        if space == nil {
            space = LockScreenSpace()
        }
        space?.add(panel)
        panel.animator().alphaValue = 1
    }

    private func hide() {
        guard let panel else { return }
        space?.remove(panel)
        panel.orderOut(nil)
        // Drop the card and the space, so nothing of Lyric stays above the system or keeps
        // following the song unseen while unlocked. Both are made again on the next lock.
        self.panel = nil
        space = nil
    }

    private func reposition() {
        guard let panel, let screen = NSScreen.screens.first else { return }
        let frame = screen.frame
        let size = LockScreenLayout.cardSize(showsLyrics: settings.lockScreenShowsLyrics)
        let margin = max(frame.width * 0.05, 48)
        let x = switch settings.lockScreenPlacement {
        case .belowClock: frame.midX - size.width / 2
        case .left: frame.minX + margin
        case .right: frame.maxX - margin - size.width
        }
        let top = frame.maxY - frame.height * min(max(settings.lockScreenHeight, 0.1), 0.7)
        panel.setFrame(NSRect(x: x, y: top - size.height, width: size.width, height: size.height), display: true)
    }

    private func makePanel() -> NSPanel {
        let rootView = LockScreenPlayerView()
            .environment(nowPlaying)
            .environment(settings)

        let panel = LockScreenPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 560),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: rootView)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.appearance = NSAppearance(named: .darkAqua)
        // Display only: clicks go straight through to the lock screen.
        panel.ignoresMouseEvents = true
        panel.alphaValue = 0
        return panel
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name, perform: @escaping @Sendable @MainActor (LockScreenController) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                perform(self)
            }
        }
        observers.append((center, token))
    }
}

/// A panel that never takes keyboard focus away from the password field.
final class LockScreenPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Size of the lock screen card.
enum LockScreenLayout {
    static func cardSize(showsLyrics: Bool) -> CGSize {
        CGSize(width: 400, height: showsLyrics ? 440 : 160)
    }
}
