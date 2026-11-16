import SwiftUI

/// The lock screen card: cover, song, live lyrics, progress and controls on a glass panel
/// tinted with the artwork, in the spirit of the iPhone's lock screen player.
struct LockScreenPlayerView: View {
    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let track = nowPlaying.track {
                header(for: track)
                LockScreenLyricsView()
                    .frame(maxHeight: .infinity)
                LockScreenProgress()
                LockScreenControls()
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

/// Big, centred lyrics that follow the song; just the title when there are none.
struct LockScreenLyricsView: View {
    @Environment(NowPlayingController.self) private var nowPlaying
    @State private var position = ScrollPosition(idType: Int.self)

    var body: some View {
        switch nowPlaying.lyrics {
        case .loaded(let lyrics):
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(lyrics.lines) { line in
                        let isCurrent = !lyrics.isSynced || line.id == nowPlaying.currentLyricIndex
                        Text(line.isBreak ? "♪" : line.text)
                            .font(.system(size: 28, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.white.opacity(isCurrent ? 1 : 0.32))
                            .blur(radius: isCurrent || !lyrics.isSynced ? 0 : 0.6)
                            .scaleEffect(isCurrent ? 1 : 0.94, anchor: .leading)
                            .animation(Theme.Motion.lyric, value: isCurrent)
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 120)
            }
            .scrollPosition($position, anchor: .center)
            .scrollIndicators(.hidden)
            .scrollDisabled(lyrics.isSynced)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.18),
                        .init(color: .black, location: 0.82),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .onChange(of: nowPlaying.currentLyricIndex, initial: true) { _, index in
                guard let index else { return }
                withAnimation(Theme.Motion.lyric) {
                    position.scrollTo(id: index, anchor: .center)
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
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34))
            Text(title)
                .font(.title3.weight(.semibold))
        }
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

/// Previous, play/pause and next, sized for a quick click on the lock screen.
struct LockScreenControls: View {
    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        HStack {
            Spacer()
            Button("Previous Track", systemImage: "backward.fill", action: nowPlaying.previousTrack)
            Spacer()
            Button(
                nowPlaying.isPlaying ? LocalizedStringKey("Pause") : "Play",
                systemImage: nowPlaying.isPlaying ? "pause.fill" : "play.fill",
                action: nowPlaying.togglePlayPause
            )
            .font(.system(size: 40))
            .contentTransition(.symbolEffect(.replace))
            Spacer()
            Button("Next Track", systemImage: "forward.fill", action: nowPlaying.nextTrack)
            Spacer()
        }
        .font(.system(size: 28))
        .labelStyle(.iconOnly)
        .buttonStyle(TransportButtonStyle())
        .frame(height: 52)
    }
}
