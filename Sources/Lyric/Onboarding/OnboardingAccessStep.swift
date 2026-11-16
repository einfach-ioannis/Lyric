import SwiftUI

struct OnboardingAccessStep: View {
    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        VStack(spacing: Theme.Spacing.extraLarge) {
            OnboardingHeader(
                systemImage: "lock.shield",
                title: "Allow Access to Your Music",
                subtitle: "Lyric asks Music and Spotify what’s playing. macOS will ask you once to allow this."
            )

            if nowPlaying.needsAutomationPermission {
                Label("Access is turned off", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Button("Open Privacy & Security", action: openPrivacySettings)
            } else if nowPlaying.track != nil {
                Label("Lyric can see what’s playing", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Check Access", action: nowPlaying.refresh)
                    .controlSize(.large)
                Text("Start a song in Music or Spotify first, then click “Check Access”.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }
}
