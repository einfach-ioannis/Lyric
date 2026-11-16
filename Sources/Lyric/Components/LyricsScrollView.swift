import SwiftUI

/// Lyrics that follow the song, keeping the sung line centred. Click a line to jump to it.
struct LyricsScrollView: View {
    let lyrics: Lyrics
    let currentIndex: Int?

    @Environment(NowPlayingController.self) private var nowPlaying
    @State private var position = ScrollPosition(idType: Int.self)

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(lyrics.lines) { line in
                    if lyrics.isSynced {
                        Button {
                            seek(to: line)
                        } label: {
                            LyricLineView(line: line, isSynced: true, isCurrent: line.id == currentIndex)
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
        .onChange(of: currentIndex, initial: true) { _, newIndex in
            follow(newIndex)
        }
    }

    private func follow(_ index: Int?) {
        guard let index else { return }
        withAnimation(Theme.Motion.lyric) {
            position.scrollTo(id: index, anchor: .center)
        }
    }

    private func seek(to line: LyricLine) {
        nowPlaying.seek(to: line.time)
    }
}
