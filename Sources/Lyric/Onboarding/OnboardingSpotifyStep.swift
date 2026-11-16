import SwiftUI

struct OnboardingSpotifyStep: View {
    @Environment(LibraryController.self) private var library

    var body: some View {
        VStack(spacing: Theme.Spacing.extraLarge) {
            OnboardingHeader(
                systemImage: "link",
                title: "Connect Spotify (Optional)",
                subtitle: "For favorites, playlists and Up Next. Lyrics and controls work without it."
            )

            if library.spotifyConnection.isConnected {
                Label(library.spotifyConnection.statusText, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Set Up in Settings", systemImage: "gearshape", action: showSettings)
                    .controlSize(.large)
                Text("You’ll need a free Client ID from the Spotify Developer Dashboard. Settings walks you through it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func showSettings() {
        SettingsWindowController.shared.show()
    }
}
