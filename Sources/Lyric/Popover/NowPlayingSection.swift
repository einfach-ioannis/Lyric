import SwiftUI

/// Header, scrubber, transport and tabs: the top half of the popover.
struct NowPlayingSection: View {
    let track: Track
    @Binding var tab: PopoverTab

    var body: some View {
        VStack(spacing: 18) {
            NowPlayingHeader(track: track)
            ProgressScrubber()
            PopoverTransportRow()
            PopoverTabBar(selection: $tab)
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, Theme.Spacing.small)
    }
}

/// Lyrics · Up Next · Playlists as soft glass pills, instead of a system segmented control.
struct PopoverTabBar: View {
    @Binding var selection: PopoverTab
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 4) {
            ForEach(PopoverTab.allCases) { tab in
                Button {
                    withAnimation(Theme.Motion.quick) { selection = tab }
                } label: {
                    Text(tab.title)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white.opacity(selection == tab ? 1 : 0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background {
                            if selection == tab {
                                Capsule()
                                    .fill(.white.opacity(0.18))
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(3)
        .background(.white.opacity(0.07), in: .capsule)
    }
}
