import SwiftUI

/// Cover art loaded from a URL, with the shared placeholder while loading or missing.
struct RemoteArtwork: View {
    let url: URL?
    let size: Double
    let cornerRadius: Double

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                ArtworkPlaceholder(size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: cornerRadius))
        .accessibilityHidden(true)
    }
}
