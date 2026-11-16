import SwiftUI

/// Three dots that light up one after another across an instrumental break, breathing
/// gently, and shrink away just before the singing comes back.
struct BreakDots: View {
    let start: TimeInterval
    let end: TimeInterval
    let isCurrent: Bool
    let size: CGFloat

    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !isCurrent || !nowPlaying.isPlaying)) { context in
            let time = nowPlaying.lyricTime(at: context.date)
            let duration = max(end - start, 0.1)
            let progress = isCurrent ? min(max((time - start) / duration, 0), 1) : 0
            let breathe = isCurrent ? 1 + 0.12 * sin(context.date.timeIntervalSinceReferenceDate * 2.4) : 1
            // Fold away in the last moment before the next line.
            let fold = isCurrent ? min(max((end - time) / 0.4, 0), 1) : 1

            HStack(spacing: size * 0.55) {
                ForEach(0..<3, id: \.self) { index in
                    let lit = min(max(progress * 3 - Double(index), 0), 1)
                    Circle()
                        .fill(.white.opacity(0.3 + 0.7 * lit))
                        .frame(width: size, height: size)
                }
            }
            .scaleEffect(breathe * fold, anchor: .leading)
            .opacity(fold)
            .padding(.vertical, size * 0.6)
        }
    }
}
