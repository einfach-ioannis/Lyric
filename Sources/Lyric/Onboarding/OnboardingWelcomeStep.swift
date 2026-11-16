import SwiftUI

struct OnboardingWelcomeStep: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.extraLarge) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)
            VStack(spacing: Theme.Spacing.small) {
                Text("Welcome to Lyric")
                    .font(.largeTitle)
                    .bold()
                Text("Your music, right in the menu bar.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                OnboardingFeatureRow(systemImage: "quote.bubble", title: "Live lyrics", detail: "Synced lyrics follow the song as it plays.")
                OnboardingFeatureRow(systemImage: "playpause", title: "Controls at a glance", detail: "Play, skip, shuffle and like songs without switching apps.")
                OnboardingFeatureRow(systemImage: "lock.display", title: "Lock Screen player", detail: "Live lyrics and controls while your Mac is locked.")
                OnboardingFeatureRow(systemImage: "music.note.list", title: "Spotify and Music", detail: "Works with whichever app is playing.")
            }
        }
    }
}
