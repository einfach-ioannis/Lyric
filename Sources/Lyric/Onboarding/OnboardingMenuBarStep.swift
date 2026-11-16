import SwiftUI

struct OnboardingMenuBarStep: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        VStack(spacing: Theme.Spacing.extraLarge) {
            OnboardingHeader(
                systemImage: "menubar.rectangle",
                title: "Choose Your Menu Bar Style",
                subtitle: "You can change this any time in Settings."
            )

            Picker("Show in menu bar", selection: $settings.menuBarDisplay) {
                ForEach(MenuBarDisplay.allCases) { display in
                    Text(display.localizedName).tag(display)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
        }
    }
}
