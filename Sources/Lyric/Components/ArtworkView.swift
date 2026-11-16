import SwiftUI

struct ArtworkView: View {
    let image: NSImage?
    let size: Double
    let cornerRadius: Double

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else {
                ArtworkPlaceholder(size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.25), radius: size / 12, y: size / 24)
        .animation(.smooth, value: image)
        .accessibilityHidden(true)
    }
}
