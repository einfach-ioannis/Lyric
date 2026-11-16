import AppKit
import Observation
import SwiftUI

/// The single source of truth for what is playing, shared by the menu bar label and popover.
@Observable
final class NowPlayingController {
    private(set) var track: Track?
    private(set) var isPlaying = false {
        didSet { if isPlaying != oldValue { updatePausedLong() } }
    }
    /// True once playback has stayed paused past `pauseCollapseDelay`, so short pauses keep the full menu bar item.
    private(set) var isPausedLong = false
    @ObservationIgnored private var pausedLongTask: Task<Void, Never>?
    private let pauseCollapseDelay: Duration = .seconds(10)
    private(set) var artwork: NSImage?
    private(set) var accent: Color = .white
    private(set) var lyrics: LyricsState = .idle
    private(set) var currentLyricIndex: Int?
    private(set) var needsAutomationPermission = false
    /// Shuffle, repeat and volume (0...100) as reported by the player. `nil` while unknown.
    private(set) var isShuffling: Bool?
    private(set) var isRepeating: Bool?
    private(set) var volume: Double?

    /// Playback position is interpolated between polls from this anchor.
    private var anchorPosition: TimeInterval = 0
    private var anchorDate: Date = .now

    /// When the person last changed these locally; a poll arriving sooner may still carry the old value.
    @ObservationIgnored private var shuffleChangedAt: Date = .distantPast
    @ObservationIgnored private var repeatChangedAt: Date = .distantPast
    @ObservationIgnored private var volumeChangedAt: Date = .distantPast
    private let localChangeHold: TimeInterval = 1.5

    @ObservationIgnored private let bridge = PlayerBridge()
    @ObservationIgnored private let lyricsService = LyricsService()
    @ObservationIgnored private var tickTask: Task<Void, Never>?
    @ObservationIgnored private var detailsTask: Task<Void, Never>?
    @ObservationIgnored private var artworkTask: Task<Void, Never>?
    /// When the last artwork attempt for the current track finished without an image.
    @ObservationIgnored private var artworkFailedAt: Date?
    private let artworkRetryInterval: TimeInterval = 4
    @ObservationIgnored private var observers: [any NSObjectProtocol] = []

    /// Lyrics are shown a touch early so the highlight lands as the line begins.
    private let lyricLead: TimeInterval = 0.25

    var loadedLyrics: Lyrics? {
        if case .loaded(let lyrics) = lyrics { lyrics } else { nil }
    }

    var currentLyricLine: LyricLine? {
        guard case .loaded(let lyrics) = lyrics, let currentLyricIndex else { return nil }
        return lyrics.lines[currentLyricIndex]
    }

    func position(at date: Date) -> TimeInterval {
        guard let track else { return 0 }
        let elapsed = isPlaying ? date.timeIntervalSince(anchorDate) : 0
        let position = max(anchorPosition + elapsed, 0)
        return track.duration > 0 ? min(position, track.duration) : position
    }

    func progress(at date: Date) -> Double {
        guard let duration = track?.duration, duration > 0 else { return 0 }
        return position(at: date) / duration
    }

    // MARK: Lifecycle

    func start() {
        guard tickTask == nil else { return }
        updatePausedLong()

        let center = DistributedNotificationCenter.default()
        for source in PlayerSource.allCases {
            let observer = center.addObserver(forName: source.playbackNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.refresh()
                }
            }
            observers.append(observer)
        }

        tickTask = Task { [weak self] in
            var tick = 0
            while !Task.isCancelled {
                guard let self else { return }
                let pollEvery = isPlaying ? 8 : 12
                if tick.isMultiple(of: pollEvery) {
                    refresh()
                }
                updateLyricIndex()
                tick += 1
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    func refresh() {
        switch bridge.read(preferring: track?.source) {
        case .snapshot(let snapshot):
            apply(snapshot)
        case .nothingPlaying:
            needsAutomationPermission = false
            clear()
        case .permissionDenied:
            needsAutomationPermission = true
            clear()
        }
    }

    // MARK: Controls

    func togglePlayPause() {
        guard let track else { return }
        reanchor(to: position(at: .now))
        isPlaying.toggle()
        bridge.send(.playPause, to: track.source)
        scheduleRefresh()
    }

    func nextTrack() {
        guard let track else { return }
        bridge.send(.nextTrack, to: track.source)
        scheduleRefresh()
    }

    func previousTrack() {
        guard let track else { return }
        bridge.send(.previousTrack, to: track.source)
        scheduleRefresh()
    }

    func seek(to time: TimeInterval) {
        guard let track else { return }
        reanchor(to: time)
        bridge.send(.seek(time), to: track.source)
        updateLyricIndex()
    }

    func toggleShuffle() {
        guard let track else { return }
        let enabled = !(isShuffling ?? false)
        isShuffling = enabled
        shuffleChangedAt = .now
        bridge.send(.setShuffle(enabled), to: track.source)
        scheduleRefresh()
    }

    func toggleRepeat() {
        guard let track else { return }
        let enabled = !(isRepeating ?? false)
        isRepeating = enabled
        repeatChangedAt = .now
        bridge.send(.setRepeat(enabled), to: track.source)
        scheduleRefresh()
    }

    /// Called continuously while a slider drags, so only whole-step changes reach the player.
    func setVolume(_ volume: Double) {
        guard let track else { return }
        let clamped = VolumeLevel.clamped(volume)
        let previous = self.volume
        self.volume = clamped
        volumeChangedAt = .now
        guard VolumeLevel.needsSend(from: previous, to: clamped) else { return }
        bridge.send(.setVolume(VolumeLevel.step(clamped)), to: track.source)
    }

    func openSourceApp() {
        guard let source = track?.source,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: source.bundleIdentifier)
        else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    // MARK: State updates

    private func apply(_ snapshot: PlaybackSnapshot) {
        needsAutomationPermission = false
        let trackChanged = snapshot.track.id != track?.id
        let drift = abs(position(at: .now) - snapshot.position)

        if trackChanged || drift > 0.75 || snapshot.isPlaying != isPlaying {
            reanchor(to: snapshot.position)
        }
        isPlaying = snapshot.isPlaying
        applyModes(from: snapshot)

        if trackChanged {
            track = snapshot.track
            loadDetails(for: snapshot.track)
        } else if snapshot.track.artworkURL != track?.artworkURL {
            // Spotify often reports the previous cover (or none) right as a track changes.
            track = snapshot.track
            loadArtwork(for: snapshot.track)
        } else if artwork == nil, artworkTask == nil,
                  let failedAt = artworkFailedAt, Date.now.timeIntervalSince(failedAt) > artworkRetryInterval {
            loadArtwork(for: snapshot.track)
        }
        updateLyricIndex()
    }

    /// Shuffle, repeat and volume follow the player except shortly after a local change.
    private func applyModes(from snapshot: PlaybackSnapshot) {
        let now = Date.now
        if now.timeIntervalSince(shuffleChangedAt) > localChangeHold, snapshot.isShuffling != isShuffling {
            isShuffling = snapshot.isShuffling
        }
        if now.timeIntervalSince(repeatChangedAt) > localChangeHold, snapshot.isRepeating != isRepeating {
            isRepeating = snapshot.isRepeating
        }
        if now.timeIntervalSince(volumeChangedAt) > localChangeHold, snapshot.volume != volume {
            volume = snapshot.volume
        }
    }

    private func clear() {
        guard track != nil else { return }
        isShuffling = nil
        isRepeating = nil
        volume = nil
        detailsTask?.cancel()
        artworkTask?.cancel()
        artworkTask = nil
        artworkFailedAt = nil
        track = nil
        isPlaying = false
        artwork = nil
        accent = .white
        lyrics = .idle
        currentLyricIndex = nil
    }

    private func updatePausedLong() {
        pausedLongTask?.cancel()
        if isPlaying {
            isPausedLong = false
            return
        }
        pausedLongTask = Task { [weak self, pauseCollapseDelay] in
            try? await Task.sleep(for: pauseCollapseDelay)
            guard !Task.isCancelled, let self, !self.isPlaying else { return }
            self.isPausedLong = true
        }
    }

    private func reanchor(to position: TimeInterval) {
        anchorPosition = position
        anchorDate = .now
    }

    private func updateLyricIndex() {
        guard case .loaded(let lyrics) = lyrics else {
            if currentLyricIndex != nil { currentLyricIndex = nil }
            return
        }
        let index = lyrics.lineIndex(at: position(at: .now) + lyricLead)
        if index != currentLyricIndex {
            currentLyricIndex = index
        }
    }

    private func scheduleRefresh() {
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            refresh()
        }
    }

    private func loadDetails(for track: Track) {
        detailsTask?.cancel()
        artwork = nil
        lyrics = .loading
        currentLyricIndex = nil

        loadArtwork(for: track)

        detailsTask = Task {
            let loadedLyrics = await lyricsService.lyrics(for: track)
            guard !Task.isCancelled, self.track?.id == track.id else { return }
            withAnimation(Theme.Motion.lyric) {
                lyrics = loadedLyrics
            }
            updateLyricIndex()
        }
    }

    private func loadArtwork(for track: Track) {
        artworkTask?.cancel()
        artworkFailedAt = nil
        artworkTask = Task {
            let artworkData = await artworkData(for: track)
            guard !Task.isCancelled, self.track?.id == track.id else { return }
            artworkTask = nil
            if let artworkData, let image = NSImage(data: artworkData) {
                artwork = image
                accent = await ArtworkPalette.accent(from: artworkData) ?? .white
            } else {
                artworkFailedAt = .now
                if artwork == nil { accent = .white }
            }
        }
    }

    private func artworkData(for track: Track) async -> Data? {
        if track.source == .appleMusic, let embedded = bridge.musicArtworkData() {
            return embedded
        }
        if let url = track.artworkURL, let downloaded = await ArtworkFetcher.download(url) {
            return downloaded
        }
        return await ArtworkFetcher.search(title: track.title, artist: track.artist)
    }
}
