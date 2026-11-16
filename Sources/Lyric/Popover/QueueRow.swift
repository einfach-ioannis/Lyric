import SwiftUI

struct QueueRow: View {
    let item: QueueItem

    var body: some View {
        HStack(spacing: Theme.Spacing.regular) {
            RemoteArtwork(url: item.artworkURL, size: Theme.Popover.queueArtworkSize, cornerRadius: Theme.Radius.artworkSmall)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .lineLimit(1)
                Text(item.artist)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(Duration.seconds(item.duration), format: .time(pattern: .minuteSecond))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, Theme.Spacing.small)
        .padding(.vertical, Theme.Spacing.compact)
        .accessibilityElement(children: .combine)
    }
}
