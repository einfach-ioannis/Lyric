// Renders the installer background. (The README banner comes from scripts/make-banner.swift.)
// Run from the repository root with: swift scripts/make-artwork.swift
import AppKit
import SwiftUI

let pink = Color(red: 1.0, green: 0.36, blue: 0.45)
let purple = Color(red: 0.55, green: 0.2, blue: 0.95)

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
    try FileManager.default.createDirectory(atPath: "build", withIntermediateDirectories: true)
    try write(InstallerBackground(), scale: 1, to: "scripts/dmg/background.png")
    try write(InstallerBackground(), scale: 2, to: "scripts/dmg/background@2x.png")
}
