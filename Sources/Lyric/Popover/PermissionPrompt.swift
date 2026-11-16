import SwiftUI

struct PermissionPrompt: View {
    var body: some View {
        ContentUnavailableView {
            Label("Allow Access to Your Music", systemImage: "lock.shield")
        } description: {
            Text("Lyric needs Automation permission to see what’s playing in Music and Spotify.")
        } actions: {
            Button("Open Privacy & Security", action: openPrivacySettings)
                .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, Theme.Spacing.large)
    }

    private func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }
}
