import SwiftUI

/// Lyrics that follow the song, keeping the sung line centred. Click a line to jump to it.
struct LyricsScrollView: View {
    let lyrics: Lyrics
    let currentIndex: Int?

    @Environment(NowPlayingController.self) private var nowPlaying
    @State private var position = ScrollPosition(idType: Int.self)
    /// Off once the user scrolls the lyrics themselves, until they jump back.
    @State private var isFollowing = true

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(lyrics.lines) { line in
                    if lyrics.isSynced {
                        Button {
                            seek(to: line)
                        } label: {
                            LyricLineView(
                                line: line,
                                isSynced: true,
                                isCurrent: line.id == currentIndex,
                                distance: isFollowing ? currentIndex.map { abs(line.id - $0) } : nil,
                                nextTime: line.id + 1 < lyrics.lines.count ? lyrics.lines[line.id + 1].time : nil
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        LyricLineView(line: line, isSynced: false, isCurrent: false)
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 22)
            // Start right at the top so there's no empty gap before the first line,
            // but leave room below so the last lines can still scroll to the centre.
            .padding(.top, Theme.Spacing.large)
            .padding(.bottom, Theme.Popover.contentHeight / 2)
        }
        .scrollPosition($position, anchor: .center)
        .scrollIndicators(.hidden)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.06),
                    .init(color: .black, location: 0.85),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .onScrollPhaseChange { _, phase in
            if phase == .interacting, lyrics.isSynced {
                withAnimation(.smooth) { isFollowing = false }
            }
        }
        .overlay(alignment: .bottom) {
            if !isFollowing, currentIndex != nil {
                Button("Back to Current Line", systemImage: "arrow.down.to.line.compact", action: resync)
                    .buttonStyle(ResyncButtonStyle())
                    .padding(.bottom, Theme.Spacing.medium)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: currentIndex, initial: true) { _, newIndex in
            if isFollowing { follow(newIndex) }
        }
        .onChange(of: lyrics) {
            isFollowing = true
        }
    }

    private func follow(_ index: Int?) {
        guard let index else { return }
        withAnimation(Theme.Motion.lyric) {
            position.scrollTo(id: index, anchor: .center)
        }
    }

    private func resync() {
        withAnimation(.smooth) { isFollowing = true }
        follow(currentIndex)
    }

    private func seek(to line: LyricLine) {
        nowPlaying.seek(to: line)
        withAnimation(.smooth) { isFollowing = true }
    }
}

/// A small glass capsule floating over the lyrics.
private struct ResyncButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .glassEffect(.regular.interactive(), in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }
}
