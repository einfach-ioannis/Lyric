import SwiftUI

/// Settings with a sidebar, like System Settings: one short page per topic.
struct SettingsView: View {
    @AppStorage("settingsPane") private var pane = SettingsPane.general

    var body: some View {
        HStack(spacing: 0) {
            List(SettingsPane.allCases, selection: Binding($pane)) { item in
                Label {
                    Text(item.title)
                        .lineLimit(1)
                } icon: {
                    SettingsIcon(pane: item)
                }
                .tag(item)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .padding(.top, 40)
            .frame(width: 205)
            .background(.regularMaterial)

            Divider()

            Group {
                switch pane {
                case .general: GeneralSettingsPage()
                case .menuBar: MenuBarSettingsPage()
                case .lockScreen: LockScreenSettingsPage()
                case .spotify: SpotifySettingsPage()
                case .about: AboutSettingsPage()
                }
            }
            .formStyle(.grouped)
            .padding(.top, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(WindowTitle(title: pane.title))
        .ignoresSafeArea()
        .frame(width: 720, height: 480)
    }
}

struct GeneralSettingsPage: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Toggle("Open at login", isOn: $settings.launchAtLogin)
                if let error = settings.launchAtLoginError {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
        }
        .onChange(of: settings.launchAtLogin) {
            settings.applyLaunchAtLogin()
        }
    }
}

struct MenuBarSettingsPage: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Picker("Show in menu bar", selection: $settings.menuBarDisplay) {
                    ForEach(MenuBarDisplay.allCases) { display in
                        Text(display.localizedName).tag(display)
                    }
                }
                .pickerStyle(.radioGroup)
            }
            Section {
                Toggle("Only show the cover while paused", isOn: $settings.hidesWhenPaused)
                Toggle("Scroll over the menu bar item to change volume", isOn: $settings.scrollChangesVolume)
            }
        }
    }
}

struct LockScreenSettingsPage: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Toggle("Show player and lyrics on the Lock Screen", isOn: $settings.showsLockScreenPlayer)
                    .disabled(!LockScreenSpace.isAvailable)
            } footer: {
                Text(LockScreenSpace.isAvailable
                     ? "The song and live lyrics appear while your Mac is locked."
                     : "Not available on this version of macOS.")
            }

            if LockScreenSpace.isAvailable && settings.showsLockScreenPlayer {
                Section {
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
                } footer: {
                    HStack {
                        Spacer()
                        Button("Preview", systemImage: "eye") {
                            LockScreenController.shared?.preview()
                        }
                    }
                }
            }
        }
    }
}

struct SpotifySettingsPage: View {
    var body: some View {
        Form {
            SpotifySettingsSection()
        }
    }
}

struct AboutSettingsPage: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Spacer()
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)
            VStack(spacing: Theme.Spacing.tight) {
                Text("Lyric")
                    .font(.largeTitle.bold())
                Text("Version \(Bundle.main.shortVersion)")
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: Theme.Spacing.large) {
                Link("Lyric on GitHub", destination: AppLinks.github)
                Link("Report a Problem", destination: AppLinks.issues)
            }
            Spacer()
            Text("Lyrics by LRCLIB · Not affiliated with Apple or Spotify")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, Theme.Spacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
