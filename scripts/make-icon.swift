// Renders Resources/AppIcon.icns. Run with: swift scripts/make-icon.swift
import AppKit
import SwiftUI

struct IconView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 230)
                .fill(LinearGradient(
                    colors: [Color(red: 1.0, green: 0.36, blue: 0.45), Color(red: 0.55, green: 0.2, blue: 0.95)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: 230)
                .fill(LinearGradient(colors: [.white.opacity(0.25), .clear], startPoint: .top, endPoint: .center))
            Image(systemName: "bubble.left.fill")
                .font(.system(size: 560, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 30, y: 16)
            Image(systemName: "music.note")
                .font(.system(size: 260, weight: .bold))
                .foregroundStyle(Color(red: 0.75, green: 0.25, blue: 0.75))
                .offset(x: 0, y: -24)
        }
        .frame(width: 1024, height: 1024)
        .padding(100)
        .frame(width: 1024, height: 1024)
        .scaleEffect(1024.0 / 1224.0)
    }
}

@MainActor func render() throws {
    let iconset = URL(filePath: "build/AppIcon.iconset")
    try? FileManager.default.removeItem(at: iconset)
    try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
    for base in [16, 32, 128, 256, 512] {
        for scale in [1, 2] {
            let renderer = ImageRenderer(content: IconView())
            renderer.scale = Double(base * scale) / 1024
            guard let cgImage = renderer.cgImage else { continue }
            let rep = NSBitmapImageRep(cgImage: cgImage)
            let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
            try rep.representation(using: .png, properties: [:])?.write(to: iconset.appending(path: name))
        }
    }
}

try MainActor.assumeIsolated { try render() }
