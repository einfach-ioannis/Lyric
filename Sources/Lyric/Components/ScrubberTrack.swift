import SwiftUI

/// A thin capsule that thickens while hovered or dragged, like the scrubber in Music.
struct ScrubberTrack: View {
    let progress: Double
    let accent: Color
    let onScrub: (Double) -> Void
    let onCommit: (Double) -> Void

    @State private var width = 0.0
    @State private var isHovering = false
    @State private var isDragging = false

    private var isActive: Bool { isHovering || isDragging }

    var body: some View {
        Capsule()
            .fill(.white.opacity(0.2))
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(accent)
                    .frame(width: max(width * min(max(progress, 0), 1), isActive ? 9 : 6))
            }
            .frame(height: isActive ? 9 : 6)
            .frame(height: 16)
            .contentShape(.rect)
            .onGeometryChange(for: Double.self) { $0.size.width } action: { width = $0 }
            .onHover { isHovering = $0 }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        onScrub(fraction(at: value.location.x))
                    }
                    .onEnded { value in
                        isDragging = false
                        onCommit(fraction(at: value.location.x))
                    }
            )
            .animation(Theme.Motion.quick, value: isActive)
    }

    private func fraction(at x: Double) -> Double {
        guard width > 0 else { return 0 }
        return min(max(x / width, 0), 1)
    }
}
