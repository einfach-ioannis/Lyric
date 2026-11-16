import SwiftUI

struct ArtworkPlaceholder: View {
    let size: Double

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.quaternary)
            Image(systemName: "music.note")
                .font(.system(size: size * 0.4))
                .foregroundStyle(.secondary)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
