import SwiftUI

/// The pages of the Settings window.
enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case menuBar
    case lockScreen
    case spotify
    case about

    var id: Self { self }

    var title: String {
        switch self {
        case .general: String(localized: "General")
        case .menuBar: String(localized: "Menu Bar")
        case .lockScreen: String(localized: "Lock Screen")
        case .spotify: "Spotify"
        case .about: String(localized: "About")
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape.fill"
        case .menuBar: "menubar.rectangle"
        case .lockScreen: "lock.fill"
        case .spotify: "music.note"
        case .about: "info.circle.fill"
        }
    }

    /// Badge colours in the style of System Settings.
    var tint: Color {
        switch self {
        case .general: .gray
        case .menuBar: .blue
        case .lockScreen: .indigo
        case .spotify: Theme.Palette.spotify
        case .about: .pink
        }
    }
}

/// A white symbol on a rounded colour square, like the icons in System Settings.
struct SettingsIcon: View {
    let pane: SettingsPane

    var body: some View {
        Image(systemName: pane.systemImage)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(pane.tint.gradient, in: .rect(cornerRadius: 6))
    }
}

/// Names the hosting window, since a plain `NSWindow` ignores `navigationTitle`.
struct WindowTitle: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            view.window?.title = title
        }
    }
}
