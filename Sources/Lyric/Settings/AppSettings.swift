import Foundation
import Observation
import ServiceManagement

/// Preferences, persisted to `UserDefaults`.
@Observable
final class AppSettings {
    private enum Key {
        static let menuBarDisplay = "menuBarDisplay"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let scrollChangesVolume = "scrollChangesVolume"
        static let showsLockScreenPlayer = "showsLockScreenPlayer"
        static let hidesWhenPaused = "hidesWhenPaused"
        static let lockScreenPlacement = "lockScreenPlacement"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) }
    }

    var menuBarDisplay: MenuBarDisplay {
        didSet { defaults.set(menuBarDisplay.rawValue, forKey: Key.menuBarDisplay) }
    }

    /// Scrolling over the menu bar item changes the volume.
    var scrollChangesVolume: Bool {
        didSet { defaults.set(scrollChangesVolume, forKey: Key.scrollChangesVolume) }
    }

    /// Shows the large player with lyrics while the Mac is locked.
    var showsLockScreenPlayer: Bool {
        didSet { defaults.set(showsLockScreenPlayer, forKey: Key.showsLockScreenPlayer) }
    }

    /// Which side of the lock screen the player sits on.
    var lockScreenPlacement: LockScreenPlacement {
        didSet { defaults.set(lockScreenPlacement.rawValue, forKey: Key.lockScreenPlacement) }
    }

    /// Shrinks the menu bar item to the level meter while nothing is playing.
    var hidesWhenPaused: Bool {
        didSet { defaults.set(hidesWhenPaused, forKey: Key.hidesWhenPaused) }
    }

    var launchAtLogin: Bool
    private(set) var launchAtLoginError: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.menuBarDisplay: MenuBarDisplay.title.rawValue,
            Key.scrollChangesVolume: true,
            Key.showsLockScreenPlayer: true,
            Key.hidesWhenPaused: false,
        ])
        hasCompletedOnboarding = defaults.bool(forKey: Key.hasCompletedOnboarding)
        menuBarDisplay = MenuBarDisplay(rawValue: defaults.string(forKey: Key.menuBarDisplay) ?? "") ?? .title
        scrollChangesVolume = defaults.bool(forKey: Key.scrollChangesVolume)
        showsLockScreenPlayer = defaults.bool(forKey: Key.showsLockScreenPlayer)
        hidesWhenPaused = defaults.bool(forKey: Key.hidesWhenPaused)
        lockScreenPlacement = LockScreenPlacement(rawValue: defaults.string(forKey: Key.lockScreenPlacement) ?? "") ?? .left
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    /// Brings the login item registration in line with `launchAtLogin`.
    func applyLaunchAtLogin() {
        let service = SMAppService.mainApp
        let isEnabled = service.status == .enabled
        guard launchAtLogin != isEnabled else { return }

        do {
            if launchAtLogin {
                try service.register()
            } else {
                try service.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
            launchAtLogin = isEnabled
        }
    }
}
