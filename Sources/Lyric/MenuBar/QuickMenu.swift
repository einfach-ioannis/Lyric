import AppKit
import SwiftUI

/// The right-click menu of the menu bar item.
enum QuickMenu {
    static func make(nowPlaying: NowPlayingController, library: LibraryController, settings: AppSettings) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        if let track = nowPlaying.track {
            let header = NSMenuItem(title: "\(track.title) — \(track.artist)", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
            menu.addItem(.separator())

            menu.addItem(ClosureMenuItem.make(
                title: nowPlaying.isPlaying ? String(localized: "Pause") : String(localized: "Play"),
                symbol: nowPlaying.isPlaying ? "pause.fill" : "play.fill",
                action: nowPlaying.togglePlayPause
            ))
            menu.addItem(ClosureMenuItem.make(title: String(localized: "Next Track"), symbol: "forward.fill", action: nowPlaying.nextTrack))
            menu.addItem(ClosureMenuItem.make(title: String(localized: "Previous Track"), symbol: "backward.fill", action: nowPlaying.previousTrack))

            if let isFavorite = library.isFavorite {
                menu.addItem(ClosureMenuItem.make(
                    title: isFavorite ? String(localized: "Remove from Favorites") : String(localized: "Add to Favorites"),
                    symbol: isFavorite ? "heart.slash" : "heart",
                    action: library.toggleFavorite
                ))
            }

            menu.addItem(.separator())
            menu.addItem(ClosureMenuItem.make(title: String(localized: "Copy Song and Artist"), symbol: "doc.on.doc") {
                SongActions.copyInfo(track)
            })
            if let lyrics = nowPlaying.loadedLyrics {
                menu.addItem(ClosureMenuItem.make(title: String(localized: "Copy Lyrics"), symbol: "quote.bubble") {
                    SongActions.copyLyrics(lyrics)
                })
            }
            menu.addItem(ClosureMenuItem.make(title: String(localized: "Open \(track.source.displayName)"), symbol: "arrow.up.forward.app", action: nowPlaying.openSourceApp))
        } else {
            let header = NSMenuItem(title: String(localized: "Nothing Playing"), action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
        }

        menu.addItem(.separator())
        if LockScreenSpace.isAvailable {
            let lockItem = ClosureMenuItem.make(title: String(localized: "Lock Screen Player"), symbol: "lock.display") {
                settings.showsLockScreenPlayer.toggle()
            }
            lockItem.state = settings.showsLockScreenPlayer ? .on : .off
            menu.addItem(lockItem)
        }
        settings.refreshLaunchAtLogin()
        let loginItem = ClosureMenuItem.make(title: String(localized: "Open at Login"), symbol: "power.circle") {
            settings.launchAtLogin.toggle()
            settings.applyLaunchAtLogin()
        }
        loginItem.state = settings.launchAtLogin ? .on : .off
        menu.addItem(loginItem)
        menu.addItem(ClosureMenuItem.make(title: String(localized: "Settings…"), symbol: "gearshape") {
            SettingsWindowController.shared.show()
        })
        menu.addItem(ClosureMenuItem.make(title: String(localized: "Quit Lyric"), symbol: "power") {
            NSApp.terminate(nil)
        })
        return menu
    }
}

/// Builds a menu item that runs a closure.
enum ClosureMenuItem {
    static func make(title: String, symbol: String? = nil, action handler: @escaping () -> Void) -> NSMenuItem {
        let target = MenuActionTarget(handler: handler)
        let item = NSMenuItem(title: title, action: #selector(MenuActionTarget.run), keyEquivalent: "")
        item.target = target
        // The item keeps its target alive; `target` itself is weak.
        item.representedObject = target
        if let symbol {
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        }
        return item
    }
}

final class MenuActionTarget: NSObject {
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    @objc func run() {
        handler()
    }
}
