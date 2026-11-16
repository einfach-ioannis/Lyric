import SwiftUI

struct OnboardingDoneStep: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        VStack(spacing: Theme.Spacing.extraLarge) {
            OnboardingHeader(
                systemImage: "checkmark.circle",
                title: "You’re All Set",
                subtitle: "Click Lyric in the menu bar to see the player and lyrics."
            )

            VStack(spacing: Theme.Spacing.small) {
                Toggle("Open Lyric at login", isOn: $settings.launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: settings.launchAtLogin) {
                        settings.applyLaunchAtLogin()
                    }
                if let error = settings.launchAtLoginError {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
            .onAppear(perform: settings.refreshLaunchAtLogin)
        }
    }
}
