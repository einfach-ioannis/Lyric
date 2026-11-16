import SwiftUI

/// The lock screen card: cover, song, a few lines of live lyrics and progress on a glass
/// panel tinted with the artwork. Display only — no controls on the lock screen.
struct LockScreenPlayerView: View {
    @Environment(NowPlayingController.self) private var nowPlaying
    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let track = nowPlaying.track {
                header(for: track)
                if settings.lockScreenShowsLyrics {
                    LockScreenLyricsView()
                        .frame(maxHeight: .infinity)
                }
                LockScreenProgress()
            }
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                ArtworkBackdrop(image: nowPlaying.artwork, accent: nowPlaying.accent)
                Color.black.opacity(0.2)
            }
            .clipShape(.rect(cornerRadius: 34))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 34)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }

    private func header(for track: Track) -> some View {
        HStack(spacing: 14) {
            ArtworkView(image: nowPlaying.artwork, size: 64, cornerRadius: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                Text(track.artist)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            EqualizerBars(isPlaying: nowPlaying.isPlaying, color: nowPlaying.accent == .white ? .white : nowPlaying.accent, height: 16)
        }
        .contentTransition(.opacity)
        .animation(.smooth, value: track)
    }
}

/// A few lines of lyrics around the one being sung; starts at the top of the song with no gap.
struct LockScreenLyricsView: View {
    @Environment(NowPlayingController.self) private var nowPlaying
    @State private var position = ScrollPosition(idType: Int.self)

    var body: some View {
        switch nowPlaying.lyrics {
        case .loaded(let lyrics):
            GeometryReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(lyrics.lines) { line in
                            LyricLineView(
                                line: line,
                                isSynced: lyrics.isSynced,
                                isCurrent: line.id == nowPlaying.currentLyricIndex,
                                distance: nowPlaying.currentLyricIndex.map { abs(line.id - $0) },
                                nextTime: line.id + 1 < lyrics.lines.count ? lyrics.lines[line.id + 1].time : nil,
                                fontSize: 28
                            )
                        }
                    }
                    .scrollTargetLayout()
                    // No space above the first line, so the song starts at the top; room
                    // below so the last lines can still reach the middle.
                    .padding(.bottom, proxy.size.height / 2)
                }
                .scrollPosition($position, anchor: .center)
                .scrollIndicators(.hidden)
                .scrollDisabled(true)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.08),
                            .init(color: .black, location: 0.8),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .onChange(of: nowPlaying.currentLyricIndex, initial: true) { _, index in
                withAnimation(Theme.Motion.lyric) {
                    position.scrollTo(id: index ?? 0, anchor: .center)
                }
            }
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .instrumental:
            placeholder("Instrumental", systemImage: "pianokeys")
        case .idle, .unavailable:
            placeholder("No Lyrics", systemImage: "quote.bubble")
        }
    }

    private func placeholder(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white.opacity(0.45))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A slim, read-only progress bar with elapsed and remaining time.
struct LockScreenProgress: View {
    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let duration = nowPlaying.track?.duration ?? 0
            let progress = nowPlaying.progress(at: context.date)
            VStack(spacing: 6) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(.white)
                                .frame(width: max(proxy.size.width * progress, 6))
                        }
                }
                .frame(height: 6)
                HStack {
                    Text(Duration.seconds(progress * duration), format: .time(pattern: .minuteSecond))
                    Spacer()
                    Text("−\(Duration.seconds(max(duration - progress * duration, 0)).formatted(.time(pattern: .minuteSecond)))")
                }
                .font(.caption.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}
