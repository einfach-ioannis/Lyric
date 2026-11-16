import SwiftUI

struct ProgressScrubber: View {
    var showsTimes = true

    @Environment(NowPlayingController.self) private var nowPlaying
    @State private var scrubProgress: Double?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let duration = nowPlaying.track?.duration ?? 0
            let progress = scrubProgress ?? nowPlaying.progress(at: context.date)
            let elapsed = Duration.seconds(progress * duration)
            let remaining = Duration.seconds(max(duration - progress * duration, 0))

            VStack(spacing: Theme.Spacing.tight) {
                ScrubberTrack(progress: progress, accent: .white, onScrub: scrub, onCommit: commit)

                if showsTimes {
                    HStack {
                        Text(elapsed, format: .time(pattern: .minuteSecond))
                        Spacer()
                        Text("−\(remaining.formatted(.time(pattern: .minuteSecond)))")
                    }
                    .font(.caption.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.6))
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Playback Position")
            .accessibilityValue(elapsed.formatted(.units(allowed: [.minutes, .seconds], width: .wide)))
            .accessibilityAdjustableAction { direction in
                adjust(direction, at: context.date)
            }
        }
    }

    private func scrub(_ fraction: Double) {
        scrubProgress = fraction
    }

    private func commit(_ fraction: Double) {
        nowPlaying.seek(to: fraction * (nowPlaying.track?.duration ?? 0))
        scrubProgress = nil
    }

    private func adjust(_ direction: AccessibilityAdjustmentDirection, at date: Date) {
        let step: TimeInterval = direction == .increment ? 10 : -10
        nowPlaying.seek(to: nowPlaying.position(at: date) + step)
    }
}
