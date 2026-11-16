// Composes the README showcase images in docs/showcase from the screenshots in
// docs/screenshots and the hero background.
// Run from the repository root: swift scripts/make-showcase.swift
import AppKit
import SwiftUI

let canvas = CGSize(width: 1600, height: 1000)

/// The hero background, darkened and blurred so a screenshot reads clearly on top of it.
struct Backdrop: View {
    let image: NSImage
    var darkness = 0.35
    var blur = 30.0

    var body: some View {
        ZStack {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: canvas.width, height: canvas.height)
                .blur(radius: blur)
                .clipped()
            Color.black.opacity(darkness)
            RadialGradient(colors: [.clear, .black.opacity(0.55)], center: .center, startRadius: 300, endRadius: 1100)
        }
    }
}

/// A screenshot with a soft, deep shadow and a faint glow behind it.
struct Floating: View {
    let image: NSImage
    let width: Double
    var glow: Color = Color(red: 0.75, green: 0.3, blue: 0.95)

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .background {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                    .blur(radius: 60)
                    .opacity(0.7)
            }
            .shadow(color: .black.opacity(0.6), radius: 50, y: 30)
    }
}

/// A headline and a line of copy beside a screenshot.
struct Caption: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.system(size: 64, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
        }
        .foregroundStyle(.white)
        .frame(width: 600, alignment: .leading)
    }
}

struct PlayerShowcase: View {
    let background: NSImage
    let popover: NSImage
    let artwork: NSImage

    private let popoverWidth = 500.0
    private let popoverCenterX = 1130.0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Backdrop(image: background, darkness: 0.25, blur: 10)

            // A slice of menu bar with Lyric's item, the cover of the song playing.
            HStack(spacing: 26) {
                Spacer()
                Image(nsImage: artwork)
                    .resizable()
                    .frame(width: 26, height: 26)
                    .clipShape(.rect(cornerRadius: 5))
                    .padding(.trailing, canvas.width - popoverCenterX - 13 - 360)
                Image(systemName: "wifi")
                Image(systemName: "battery.75percent")
                Text("Mon 16 Nov  9:41")
            }
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 40)
            .frame(width: canvas.width, height: 46)
            .background(.black.opacity(0.35))

            Floating(image: popover, width: popoverWidth)
                .position(x: popoverCenterX, y: 50 + popoverWidth * popover.size.height / popover.size.width / 2)

            Caption(title: "Lyrics that\nfollow the song.", subtitle: "Synced lyrics, playback controls,\nUp Next and your playlists —\none click away in the menu bar.")
                .position(x: 120 + 300, y: canvas.height / 2 + 20)
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipped()
    }
}

struct LockShowcase: View {
    let background: NSImage
    let lock: NSImage

    var body: some View {
        ZStack {
            Backdrop(image: background, darkness: 0.45, blur: 40)
            VStack(spacing: 0) {
                Text("Monday, 16 November")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Text("9:41")
                    .font(.system(size: 150, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, -10)
                Floating(image: lock, width: 520)
                    .padding(.top, 16)
                Spacer()
            }
            .padding(.top, 40)
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipped()
    }
}

struct SettingsShowcase: View {
    let background: NSImage
    let settings: NSImage

    var body: some View {
        ZStack {
            Backdrop(image: background, darkness: 0.3, blur: 20)
            Floating(image: settings, width: 1080, glow: .purple)
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipped()
    }
}

@MainActor func write(_ view: some View, to path: String) throws {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    guard let image = renderer.cgImage,
          let data = NSBitmapImageRep(cgImage: image).representation(using: .jpeg, properties: [.compressionFactor: 0.88])
    else { throw CocoaError(.fileWriteUnknown) }
    try data.write(to: URL(filePath: path))
}

try MainActor.assumeIsolated {
    guard let background = NSImage(contentsOfFile: "docs/art/hero-background.png"),
          let popover = NSImage(contentsOfFile: "docs/screenshots/popover.png"),
          let lock = NSImage(contentsOfFile: "docs/screenshots/lock-screen.png"),
          let settings = NSImage(contentsOfFile: "docs/screenshots/settings.png")
    else { fatalError("Run from the repository root.") }

    // The cover art from the popover's header, for the menu bar item.
    let rect = CGRect(x: 70, y: 70, width: 126, height: 126)
    guard let cgPopover = popover.cgImage(forProposedRect: nil, context: nil, hints: nil),
          let cover = cgPopover.cropping(to: rect.applying(.init(scaleX: CGFloat(cgPopover.width) / 732, y: CGFloat(cgPopover.width) / 732)))
    else { fatalError("Popover screenshot has an unexpected size.") }
    let artwork = NSImage(cgImage: cover, size: rect.size)
    try write(PlayerShowcase(background: background, popover: popover, artwork: artwork), to: "docs/showcase/player.jpg")
    try write(LockShowcase(background: background, lock: lock), to: "docs/showcase/lock-screen.jpg")
    try write(SettingsShowcase(background: background, settings: settings), to: "docs/showcase/settings.jpg")
}
