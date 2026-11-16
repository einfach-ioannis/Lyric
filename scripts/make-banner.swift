// Composes docs/banner.png and docs/social-preview.png from a background image, the app
// icon and the README screenshots.
// Run from the repository root: swift scripts/make-banner.swift <background.png>
import AppKit
import SwiftUI

struct Shot: View {
    let image: NSImage
    let width: Double

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .shadow(color: .black.opacity(0.55), radius: 40, y: 24)
    }
}

struct Banner: View {
    let background: NSImage
    let icon: NSImage
    let popover: NSImage
    let lock: NSImage
    let size: CGSize
    let showsShots: Bool

    var body: some View {
        ZStack {
            Image(nsImage: background)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
            LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .leading, endPoint: .center)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 22) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: size.height * 0.27, height: size.height * 0.27)
                        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
                    Text("Lyric")
                        .font(.system(size: size.height * 0.2, weight: .bold, design: .rounded))
                    Text("Live lyrics for Spotify & Apple Music —\nin your menu bar and on the Lock Screen.")
                        .font(.system(size: size.height * 0.046, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .fixedSize()
                }
                .padding(.leading, size.width * 0.07)
                Spacer()
                if showsShots {
                    ZStack {
                        Shot(image: lock, width: size.height * 0.52)
                            .rotationEffect(.degrees(4))
                            .offset(x: size.height * 0.24, y: -size.height * 0.06)
                        Shot(image: popover, width: size.height * 0.46)
                            .rotationEffect(.degrees(-3))
                            .offset(x: -size.height * 0.2, y: size.height * 0.04)
                    }
                    .padding(.trailing, size.height * 0.3)
                }
            }
            .foregroundStyle(.white)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

@MainActor func write(_ view: some View, to path: String) throws {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    guard let image = renderer.cgImage,
          let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    else { throw CocoaError(.fileWriteUnknown) }
    try data.write(to: URL(filePath: path))
}

try MainActor.assumeIsolated {
    let args = CommandLine.arguments
    guard args.count > 1,
          let background = NSImage(contentsOfFile: args[1]),
          let icon = NSImage(contentsOfFile: "docs/icon.png"),
          let popover = NSImage(contentsOfFile: "docs/screenshots/popover.png"),
          let lock = NSImage(contentsOfFile: "docs/screenshots/lock-screen.png")
    else { fatalError("usage: swift scripts/make-banner.swift <background.png>") }
    try write(Banner(background: background, icon: icon, popover: popover, lock: lock,
                     size: CGSize(width: 1800, height: 760), showsShots: true), to: "docs/banner.png")
    try write(Banner(background: background, icon: icon, popover: popover, lock: lock,
                     size: CGSize(width: 1280, height: 640), showsShots: true), to: "docs/social-preview.png")
}
