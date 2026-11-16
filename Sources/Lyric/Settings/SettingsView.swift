import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Menu Bar") {
                Picker("Show in menu bar", selection: $settings.menuBarDisplay) {
                    ForEach(MenuBarDisplay.allCases) { display in
                        Text(display.localizedName).tag(display)
                    }
                }
                Toggle("Only show the level meter while paused", isOn: $settings.hidesWhenPaused)
                Toggle("Scroll over the menu bar item to change volume", isOn: $settings.scrollChangesVolume)
            }

            Section {
                Toggle("Show player and lyrics on the Lock Screen", isOn: $settings.showsLockScreenPlayer)
                    .disabled(!LockScreenSpace.isAvailable)
                if LockScreenSpace.isAvailable && settings.showsLockScreenPlayer {
                    Toggle("Show lyrics", isOn: $settings.lockScreenShowsLyrics)
                    Picker("Position", selection: $settings.lockScreenPlacement) {
                        ForEach(LockScreenPlacement.allCases) { placement in
                            Text(placement.localizedName).tag(placement)
                        }
                    }
                    Slider(value: $settings.lockScreenHeight, in: 0.15...0.6) {
                        Text("Height")
                    } minimumValueLabel: {
                        Image(systemName: "arrow.up.to.line")
                    } maximumValueLabel: {
                        Image(systemName: "arrow.down.to.line")
                    }
                    Button("Preview") {
                        LockScreenController.shared?.preview()
                    }
                }
            } header: {
                Text("Lock Screen")
            } footer: {
                if LockScreenSpace.isAvailable {
                    Text("The song and live lyrics appear while your Mac is locked.")
                } else {
                    Text("Not available on this version of macOS.")
                }
            }

            SpotifySettingsSection()

            Section("General") {
                Toggle("Open at login", isOn: $settings.launchAtLogin)
                if let error = settings.launchAtLoginError {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }

            Section("About") {
                LabeledContent("Version", value: Bundle.main.shortVersion)
                LabeledContent("Lyrics") {
                    Link("LRCLIB", destination: AppLinks.lrclib)
                }
                Link("Lyric on GitHub", destination: AppLinks.github)
                Link("Report a Problem", destination: AppLinks.issues)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: settings.launchAtLogin) {
            settings.applyLaunchAtLogin()
        }
    }
}
