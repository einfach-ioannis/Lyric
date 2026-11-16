import SwiftUI

/// A dark-tinted wash behind the popover: blurred cover art, with the artwork's accent
/// glowing in from the top.
struct ArtworkBackdrop: View {
    let image: NSImage?
    let accent: Color

    var body: some View {
        Theme.Palette.popoverTint
            .overlay {
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 60)
                        .saturation(1.5)
                        .opacity(Theme.Popover.artworkBlurOpacity)
                }
            }
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: accent.opacity(Theme.Popover.accentWashOpacity), location: 0),
                        .init(color: .clear, location: 0.55),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .allowsHitTesting(false)
            .animation(Theme.Motion.backdrop, value: image)
            .animation(Theme.Motion.backdrop, value: accent)
    }
}
