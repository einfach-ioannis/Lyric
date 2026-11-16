// Renders the README banner and the installer background.
// Run from the repository root with: swift scripts/make-artwork.swift
import AppKit
import SwiftUI

let pink = Color(red: 1.0, green: 0.36, blue: 0.45)
let purple = Color(red: 0.55, green: 0.2, blue: 0.95)

struct BannerView: View {
    let icon: NSImage

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.05, blue: 0.09)
            Circle().fill(pink.opacity(0.55)).frame(width: 700).blur(radius: 160).offset(x: -420, y: -160)
            Circle().fill(purple.opacity(0.6)).frame(width: 760).blur(radius: 170).offset(x: 460, y: 180)

            HStack(spacing: 56) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 220, height: 220)
                    .shadow(color: .black.opacity(0.4), radius: 30, y: 14)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Lyric")
                        .font(.system(size: 112, weight: .bold, design: .rounded))
                    Text("Live lyrics and music controls\nin your Mac’s menu bar and on the Lock Screen.")
                        .font(.system(size: 34, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .foregroundStyle(.white)
        }
        .frame(width: 1600, height: 500)
    }
}

struct InstallerBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.98), Color(white: 0.92)], startPoint: .top, endPoint: .bottom)
            Circle().fill(pink.opacity(0.18)).frame(width: 420).blur(radius: 90).offset(x: -240, y: -160)
            Circle().fill(purple.opacity(0.18)).frame(width: 420).blur(radius: 90).offset(x: 260, y: 180)
            VStack {
                Text("Drag Lyric into Applications")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(white: 0.2))
                    .padding(.top, 34)
                Spacer()
            }
            Image(systemName: "arrow.right")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: [pink, purple], startPoint: .leading, endPoint: .trailing))
                .offset(y: 0)
        }
        .frame(width: 660, height: 420)
    }
}

@MainActor func write(_ view: some View, scale: Double, to path: String) throws {
    let renderer = ImageRenderer(content: view)
    renderer.scale = scale
    guard let image = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    try data?.write(to: URL(filePath: path))
}

try MainActor.assumeIsolated {
    guard let icon = NSImage(contentsOfFile: "docs/icon.png") else { fatalError("docs/icon.png missing") }
    try write(BannerView(icon: icon), scale: 1, to: "docs/banner.png")
    try FileManager.default.createDirectory(atPath: "build", withIntermediateDirectories: true)
    try write(InstallerBackground(), scale: 1, to: "scripts/dmg/background.png")
    try write(InstallerBackground(), scale: 2, to: "scripts/dmg/background@2x.png")
}
