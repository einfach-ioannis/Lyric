import SwiftUI

/// The one-time steps for creating a Spotify app that Lyric can log in with.
struct SpotifySetupSteps: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Text("1. Open the dashboard and click **Create app**. Any name and description will do.")
            Text("2. Add the **Redirect URI** below and click **Add**.")
            Text("3. Under “Which API/SDKs are you planning to use?”, tick only **Web API**.")
            Text("4. Save, open the app’s **Settings**, and paste its **Client ID** here. No client secret is needed.")
            Link("Open Spotify Developer Dashboard", destination: AppLinks.spotifyDashboard)
                .padding(.top, Theme.Spacing.tight)
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
}
