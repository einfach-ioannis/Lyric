import AppKit
import SwiftUI

/// Owns Lyric's menu bar item and the popover it opens.
///
/// AppKit is used instead of `MenuBarExtra` so the label can contain real, clickable
/// controls (the "Playback Controls" style).
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let nowPlaying: NowPlayingController
    private let library: LibraryController
    private let settings: AppSettings

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let itemState = StatusItemState()
    private var labelView: NSView?

    init(nowPlaying: NowPlayingController, library: LibraryController, settings: AppSettings) {
        self.nowPlaying = nowPlaying
        self.library = library
        self.settings = settings
        super.init()
        configureLabel()
        configurePopover()
    }

    // MARK: Popover

    func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    func closePopover() {
        popover.close()
        itemState.isPopoverShown = false
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        itemState.isPopoverShown = true
    }

    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        // A click on the status item itself is handled by the label's own toggle on mouse-up;
        // closing here as well would immediately reopen the popover.
        guard let event = NSApp.currentEvent,
              event.type == .leftMouseDown,
              let buttonWindow = statusItem.button?.window
        else { return true }
        return event.window !== buttonWindow
    }

    func popoverDidClose(_ notification: Notification) {
        itemState.isPopoverShown = false
    }

    // MARK: Quick actions

    /// Right-click menu: the essentials without opening the popover.
    private func showQuickMenu(for event: NSEvent) {
        guard let button = statusItem.button else { return }
        if popover.isShown { closePopover() }
        let menu = QuickMenu.make(nowPlaying: nowPlaying, library: library, settings: settings)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    /// Scrolling over the menu bar item changes the player's volume.
    private func adjustVolume(for event: NSEvent) {
        guard settings.scrollChangesVolume, let volume = nowPlaying.volume else { return }
        let delta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY / 4 : event.scrollingDeltaY * 2
        let direction = event.isDirectionInvertedFromDevice ? -1.0 : 1.0
        guard abs(delta) > 0.01 else { return }
        nowPlaying.setVolume(volume + delta * direction)
    }

    // MARK: Setup

    private func configureLabel() {
        guard let button = statusItem.button else { return }
        button.setAccessibilityLabel(String(localized: "Lyric"))

        let rootView = StatusItemLabel(onToggle: { [weak self] in self?.togglePopover() })
            .environment(nowPlaying)
            .environment(settings)
            .environment(itemState)

        let hostingView = StatusItemHostingView(rootView: rootView)
        hostingView.sizingOptions = [.intrinsicContentSize]
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        hostingView.autoresizingMask = [.width, .height]
        hostingView.onIntrinsicSizeChange = { [weak self] size in
            Task { @MainActor in
                self?.resizeItem(to: size)
            }
        }
        hostingView.onRightClick = { [weak self] event in
            self?.showQuickMenu(for: event)
        }
        hostingView.onScroll = { [weak self] event in
            self?.adjustVolume(for: event)
        }

        button.addSubview(hostingView)
        labelView = hostingView
        resizeItem(to: hostingView.intrinsicContentSize)
    }

    private func configurePopover() {
        let rootView = PlayerPopoverView()
            .environment(nowPlaying)
            .environment(library)
            .environment(settings)
            .environment(\.popoverDismiss, PopoverDismissAction(controller: self))

        let hostingController = NSHostingController(rootView: rootView)
        hostingController.sizingOptions = [.preferredContentSize]

        popover.contentViewController = hostingController
        popover.behavior = .transient
        popover.animates = true
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.delegate = self
    }

    private func resizeItem(to size: NSSize) {
        guard let button = statusItem.button, let labelView else { return }
        let width = min(ceil(size.width), Theme.MenuBar.maximumWidth)
        guard width > 0 else { return }
        if statusItem.length != width {
            statusItem.length = width
        }
        labelView.frame = NSRect(x: 0, y: 0, width: width, height: button.bounds.height)
    }
}
