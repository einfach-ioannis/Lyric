import SwiftUI

/// A line of lyrics, Apple Music style: the sung line bright and full size, the others
/// smaller and dimmer, and softer the further away they are.
struct LyricLineView: View {
    let line: LyricLine
    let isSynced: Bool
    let isCurrent: Bool
    /// How many lines away from the sung line this is; `nil` while the person is scrolling,
    /// which shows every line sharp.
    var distance: Int?
    /// When the next line starts, for timing instrumental breaks.
    var nextTime: TimeInterval?
    var fontSize: CGFloat = 22

    private var isLit: Bool { isCurrent || !isSynced }

    private var blur: CGFloat {
        guard isSynced, !isCurrent, let distance else { return 0 }
        return min(CGFloat(distance), 4) * 0.5
    }

    private var opacity: Double {
        guard !isLit else { return 1 }
        guard isSynced, let distance, distance > 1 else { return 0.32 }
        return max(0.32 - Double(distance - 1) * 0.05, 0.16)
    }

    var body: some View {
        content
            // Every line is laid out at the same size, so wrapping never changes and nothing
            // below jumps; only how it's drawn changes, which animates smoothly.
            .font(.system(size: fontSize, weight: .bold))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .blur(radius: blur)
            .scaleEffect(isLit ? 1 : 0.95, anchor: .leading)
            .animation(Theme.Motion.lyric, value: isCurrent)
            .animation(Theme.Motion.lyric, value: distance)
            .contentShape(.rect)
    }

    @ViewBuilder private var content: some View {
        if line.isBreak, isSynced, let nextTime {
            BreakDots(start: line.time, end: nextTime, isCurrent: isCurrent, size: fontSize * 0.36)
        } else {
            // Fading the whole layer instead of the text colour keeps the animation on the
            // GPU; animating the colour redraws every glyph on the CPU each frame.
            Text(line.isBreak ? "♪" : line.text)
                .foregroundStyle(.white)
                .opacity(opacity)
        }
    }
}
