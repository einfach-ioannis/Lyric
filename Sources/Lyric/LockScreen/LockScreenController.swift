import AppKit
import SwiftUI

/// Shows the large player with lyrics while the Mac is locked.
///
/// The card lives in its own small borderless panel beside the system's clock and password
/// field (never on top of them), placed in a SkyLight space that draws above the lock screen.
final class LockScreenController {
    private let nowPlaying: NowPlayingController
    private let settings: AppSettings

    private var space: LockScreenSpace?
    private var panel: NSPanel?
    private var isLocked = false
    private var observers: [(NotificationCenter, any NSObjectProtocol)] = []
    private var stateObservation: Task<Void, Never>?

    init(nowPlaying: NowPlayingController, settings: AppSettings) {
        self.nowPlaying = nowPlaying
        self.settings = settings
    }

    func start() {
        guard LockScreenSpace.isAvailable, observers.isEmpty else { return }

        let distributed = DistributedNotificationCenter.default()
        observe(distributed, Notification.Name("com.apple.screenIsLocked")) { $0.setLocked(true) }
        observe(distributed, Notification.Name("com.apple.screenIsUnlocked")) { $0.setLocked(false) }

        let workspace = NSWorkspace.shared.notificationCenter
        // Waking the display can rebuild the lock screen; put the card back on top.
        observe(workspace, NSWorkspace.screensDidWakeNotification) { $0.update() }
        observe(workspace, NSWorkspace.sessionDidBecomeActiveNotification) { $0.setLocked(false) }
        observe(NotificationCenter.default, NSApplication.didChangeScreenParametersNotification) { $0.reposition() }

        // Show or hide as music starts and stops, or the setting changes, while locked.
        let changes = Observations { [nowPlaying, settings] in
            (nowPlaying.track != nil, settings.showsLockScreenPlayer, settings.lockScreenPlacement)
        }
        stateObservation = Task { [weak self] in
            for await _ in changes {
                self?.update()
            }
        }
    }

    #if DEBUG
    /// Shows the card on the desktop for a few seconds, for checking the design.
    func preview() {
        let panel = panel ?? makePanel()
        self.panel = panel
        reposition()
        panel.alphaValue = 1
        panel.orderFrontRegardless()
    }
    #endif

    // MARK: State

    private func setLocked(_ locked: Bool) {
        isLocked = locked
        update()
    }

    private func update() {
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
        panel.alphaValue = 0
        // Drop the space too, so nothing of Lyric stays above the system while unlocked.
        space = nil
    }

    private func reposition() {
        guard let panel, let screen = NSScreen.screens.first else { return }
        let frame = screen.frame
        let size = LockScreenLayout.cardSize(for: frame.size)
        let margin = LockScreenLayout.margin(for: frame.size)
        let x = switch settings.lockScreenPlacement {
        case .left: frame.minX + margin
        case .right: frame.maxX - margin - size.width
        }
        let y = frame.midY - size.height / 2
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
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

/// A panel that takes clicks for the controls without ever taking keyboard focus away from
/// the password field.
final class LockScreenPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Size and placement of the lock screen card, scaled to the display.
enum LockScreenLayout {
    static func cardSize(for screen: CGSize) -> CGSize {
        let width = min(max(screen.width * 0.26, 360), 460)
        let height = min(max(screen.height * 0.62, 480), 640)
        return CGSize(width: width, height: height)
    }

    static func margin(for screen: CGSize) -> Double {
        max(screen.width * 0.05, 48)
    }
}
