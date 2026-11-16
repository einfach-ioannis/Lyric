import AppKit
import SwiftUI

/// The redirect URI with a one-click copy button, for pasting into the Spotify dashboard.
struct SpotifyRedirectURIRow: View {
    @State private var didCopy = false

    var body: some View {
        LabeledContent("Redirect URI") {
            HStack(spacing: Theme.Spacing.small) {
                Text(AppLinks.spotifyRedirectURI)
                    .monospaced()
                    .textSelection(.enabled)

                Button(didCopy ? "Copied" : "Copy", systemImage: didCopy ? "checkmark" : "doc.on.doc", action: copy)
                    .contentTransition(.symbolEffect(.replace))
                    .help("Copy redirect URI")
            }
        }
        .task(id: didCopy) {
            guard didCopy else { return }
            try? await Task.sleep(for: .seconds(1.5))
            didCopy = false
        }
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(AppLinks.spotifyRedirectURI, forType: .string)
        withAnimation(Theme.Motion.quick) {
            didCopy = true
        }
    }
}
