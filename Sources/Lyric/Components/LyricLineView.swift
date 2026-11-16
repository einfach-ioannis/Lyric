import SwiftUI

struct LyricLineView: View {
    let line: LyricLine
    let isSynced: Bool
    let isCurrent: Bool

    private var isLit: Bool { isCurrent || !isSynced }

    var body: some View {
        Text(line.isBreak ? "♪" : line.text)
            // Every line is laid out at the same size, so wrapping never changes and nothing
            // below jumps. The sung line is drawn full size and bright; the others slightly
            // smaller, dimmer and softer, which animates smoothly because layout is untouched.
            .font(.system(size: 22, weight: .bold))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.white.opacity(isLit ? 1 : 0.32))
            .blur(radius: isLit ? 0 : 0.5)
            .scaleEffect(isLit ? 1 : 0.94, anchor: .leading)
            .animation(Theme.Motion.lyric, value: isCurrent)
            .contentShape(.rect)
    }
}
