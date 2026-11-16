import AppKit
import Observation

/// Favorites, playlists and the Up Next queue for the current player.
@Observable
final class LibraryController {
    private enum Key {
        static let spotifyClientID = "spotifyClientID"
    }

    /// `nil` while unknown (loading, or not supported for this source / not connected).
    private(set) var isFavorite: Bool?
    private(set) var playlists: [PlaylistSummary] = []
    private(set) var upNext: [QueueItem] = []
    private(set) var spotifyConnection: SpotifyConnectionState = .notConfigured
    /// The Spotify Client ID the person pasted into Settings.
    var spotifyClientID: String = "" {
        didSet { clientIDDidChange() }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let client: SpotifyAPIClient
    @ObservationIgnored private let appleMusic = AppleMusicLibrary()
    @ObservationIgnored private var currentTrack: Track?
    @ObservationIgnored private var pendingLogin: SpotifyLoginAttempt?
    @ObservationIgnored private var trackTask: Task<Void, Never>?
    @ObservationIgnored private var favoriteTask: Task<Void, Never>?
    @ObservationIgnored private var playlistsTask: Task<Void, Never>?
    @ObservationIgnored private var connectTask: Task<Void, Never>?
    @ObservationIgnored private var queueTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard, tokenStore: SpotifyTokenStore = SpotifyTokenStore()) {
        self.defaults = defaults
        let clientID = (defaults.string(forKey: Key.spotifyClientID) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = tokenStore.load()
        client = SpotifyAPIClient(tokens: tokens, store: tokenStore)
        spotifyClientID = clientID

        spotifyConnection = if clientID.isEmpty {
            .notConfigured
        } else if let tokens {
            .connected(displayName: tokens.displayName)
        } else {
            .disconnected
        }
    }

    /// Called by the app whenever the current track changes (or becomes nil).
    func trackDidChange(_ track: Track?) {
        let sourceChanged = track?.source != currentTrack?.source
        currentTrack = track
        trackTask?.cancel()
        favoriteTask?.cancel()
        isFavorite = nil
        if track == nil || sourceChanged {
            upNext = []
        }
        guard let track else { return }

        switch track.source {
        case .spotify:
            guard isSpotifyConnected else {
                upNext = []
                return
            }
            let bareID = SpotifyTrackID.bareID(fromTrackID: track.id)
            trackTask = Task { [client] in
                var favorite: Bool?
                if let bareID {
                    do {
                        favorite = try await client.isSaved(trackID: bareID)
                    } catch {
                        handleSpotifyError(error)
                    }
                }
                let queue = (try? await client.queue()) ?? []
                guard !Task.isCancelled else { return }
                if isFavorite == nil {
                    isFavorite = favorite
                }
                upNext = queue
            }
        case .appleMusic:
            trackTask = Task {
                // Let a burst of track changes settle before asking Music.
                await Task.yield()
                guard !Task.isCancelled else { return }
                isFavorite = appleMusic.isCurrentTrackFavorite()
                upNext = appleMusic.upNext(limit: 10)
            }
        }
    }

    /// Reloads Up Next, e.g. after shuffle was switched and the player reordered its queue.
    /// The player needs a moment to rebuild the queue, so this asks twice.
    func refreshUpNext() {
        guard let track = currentTrack else { return }
        queueTask?.cancel()
        queueTask = Task { [client] in
            for delay in [0.6, 1.8] {
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled, currentTrack?.id == track.id else { return }
                switch track.source {
                case .spotify:
                    guard isSpotifyConnected, let queue = try? await client.queue() else { continue }
                    guard !Task.isCancelled else { return }
                    upNext = queue
                case .appleMusic:
                    upNext = appleMusic.upNext(limit: 10)
                }
            }
        }
    }

    func toggleFavorite() {
        guard let track = currentTrack, let previous = isFavorite else { return }
        let desired = !previous
        isFavorite = desired

        switch track.source {
        case .appleMusic:
            appleMusic.setCurrentTrackFavorite(desired)
            // Music reports nothing back, so read the state to catch a failed change.
            if let actual = appleMusic.isCurrentTrackFavorite() {
                isFavorite = actual
            }
        case .spotify:
            guard isSpotifyConnected, let bareID = SpotifyTrackID.bareID(fromTrackID: track.id) else {
                isFavorite = previous
                return
            }
            favoriteTask?.cancel()
            favoriteTask = Task { [client] in
                do {
                    try await client.setSaved(desired, trackID: bareID)
                } catch {
                    if currentTrack?.id == track.id {
                        isFavorite = previous
                    }
                    handleSpotifyError(error)
                }
            }
        }
    }

    /// Starts the playlist right away, without opening its song list.
    func play(_ playlist: PlaylistSummary) {
        switch playlist.source {
        case .spotify:
            // Works without Premium. If Spotify refuses the context, show it instead.
            if !SpotifyPlaylistPlayer.play(uri: playlist.id) {
                SpotifyPlaylistPlayer.open(uri: playlist.id)
            }
        case .appleMusic:
            appleMusic.play(playlist)
        }
    }

    /// Shows the playlist in its app.
    func reveal(_ playlist: PlaylistSummary) {
        switch playlist.source {
        case .spotify: SpotifyPlaylistPlayer.open(uri: playlist.id)
        case .appleMusic: appleMusic.reveal(playlist)
        }
    }

    func reloadPlaylists() {
        playlistsTask?.cancel()
        let source = currentTrack?.source ?? (isSpotifyConnected ? .spotify : .appleMusic)

        switch source {
        case .appleMusic:
            playlists = appleMusic.playlists()
        case .spotify:
            guard isSpotifyConnected else {
                playlists = []
                return
            }
            playlistsTask = Task { [client] in
                do {
                    let loaded = try await client.playlists()
                    guard !Task.isCancelled else { return }
                    playlists = loaded
                } catch {
                    handleSpotifyError(error)
                }
            }
        }
    }

    /// Starts the Spotify PKCE login in the browser.
    func connectSpotify() {
        guard !trimmedClientID.isEmpty else {
            spotifyConnection = .notConfigured
            return
        }

        let attempt = SpotifyLoginAttempt()
        do {
            let url = try attempt.authorizeURL(clientID: trimmedClientID)
            pendingLogin = attempt
            spotifyConnection = .connecting
            if !NSWorkspace.shared.open(url) {
                pendingLogin = nil
                spotifyConnection = .failed(message: String(localized: "Lyric couldn’t open the Spotify login in your browser."))
            }
        } catch {
            spotifyConnection = .failed(message: error.localizedDescription)
        }
    }

    func disconnectSpotify() {
        connectTask?.cancel()
        trackTask?.cancel()
        favoriteTask?.cancel()
        playlistsTask?.cancel()
        pendingLogin = nil
        spotifyConnection = trimmedClientID.isEmpty ? .notConfigured : .disconnected
        clearSpotifyData()
        Task { [client] in await client.signOut() }
    }

    /// Handles `lyric://spotify-callback?code=…` from the login redirect.
    func handleCallback(_ url: URL) {
        guard let attempt = pendingLogin else {
            // The login was started by an earlier launch (or another copy of Lyric).
            if !spotifyConnection.isConnected {
                spotifyConnection = .failed(message: String(localized: "That Spotify login link has expired. Click Connect to try again."))
            }
            return
        }
        pendingLogin = nil

        let code: String
        do {
            code = try attempt.authorizationCode(from: url)
        } catch {
            spotifyConnection = .failed(message: error.localizedDescription)
            return
        }

        spotifyConnection = .connecting
        let clientID = trimmedClientID
        connectTask?.cancel()
        connectTask = Task { [client] in
            do {
                let tokens = try await client.connect(code: code, verifier: attempt.verifier, clientID: clientID)
                guard !Task.isCancelled else { return }
                spotifyConnection = .connected(displayName: tokens.displayName)
                if currentTrack?.source == .spotify {
                    trackDidChange(currentTrack)
                }
                reloadPlaylists()
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                spotifyConnection = .failed(message: error.localizedDescription)
            }
        }
    }

    // MARK: - Private

    private var trimmedClientID: String {
        spotifyClientID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSpotifyConnected: Bool {
        if case .connected = spotifyConnection { true } else { false }
    }

    private func clientIDDidChange() {
        let clientID = trimmedClientID
        defaults.set(clientID, forKey: Key.spotifyClientID)

        switch spotifyConnection {
        case .notConfigured where !clientID.isEmpty:
            spotifyConnection = .disconnected
        case .disconnected where clientID.isEmpty, .failed where clientID.isEmpty:
            spotifyConnection = .notConfigured
        default:
            break
        }
    }

    /// Drops the session when Spotify no longer accepts it; other errors keep the last good data.
    private func handleSpotifyError(_ error: any Error) {
        guard let spotifyError = error as? SpotifyError,
              spotifyError == .sessionExpired || spotifyError == .notSignedIn,
              isSpotifyConnected
        else { return }
        spotifyConnection = .failed(message: spotifyError.localizedDescription)
        clearSpotifyData()
    }

    private func clearSpotifyData() {
        playlists.removeAll { $0.source == .spotify }
        if currentTrack?.source == .spotify {
            isFavorite = nil
            upNext = []
        }
    }
}
