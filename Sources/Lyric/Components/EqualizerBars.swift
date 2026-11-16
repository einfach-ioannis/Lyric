import SwiftUI

/// A small animated level meter that settles when playback pauses.
struct EqualizerBars: View {
    let isPlaying: Bool
    let color: Color
    var height = 14.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let speeds = [5.1, 7.3, 4.2, 6.6]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isPlaying || reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2) {
                ForEach(speeds.indices, id: \.self) { index in
                    Capsule()
                        .fill(color)
                        .frame(width: 3, height: barHeight(index: index, time: time))
                }
            }
            .frame(height: height)
        }
        .animation(.smooth, value: isPlaying)
        .accessibilityHidden(true)
    }

    private func barHeight(index: Int, time: Double) -> Double {
        guard isPlaying, !reduceMotion else { return height * 0.3 }
        let wave = (sin(time * speeds[index] + Double(index) * 1.7) + 1) / 2
        return height * (0.25 + 0.75 * wave)
    }
}
