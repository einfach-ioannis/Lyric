import AppKit

/// Favorites and playlists for Apple Music via AppleScript.
///
/// Every call is a no-op (or returns empty/`nil`) while Music isn't running, so it never launches it.
final class AppleMusicLibrary {
    private let runner = AppleScriptRunner()

    /// Whether the current Music track is favorited, or `nil` if unknown.
    func isCurrentTrackFavorite() -> Bool? {
        guard let output = run(AppleMusicScripts.currentTrackFavorite) else { return nil }
        return AppleMusicScripts.parseFavorite(output)
    }

    func setCurrentTrackFavorite(_ favorite: Bool) {
        _ = run(AppleMusicScripts.setCurrentTrackFavorite(favorite))
    }

    /// The person's user playlists (not smart/system ones like Library or Music Videos).
    func playlists() -> [PlaylistSummary] {
        AppleMusicScripts.parsePlaylists(run(AppleMusicScripts.playlists))
    }

    func play(_ playlist: PlaylistSummary) {
        guard playlist.source == .appleMusic else { return }
        _ = run(AppleMusicScripts.play(playlistID: playlist.id))
    }

    func reveal(_ playlist: PlaylistSummary) {
        guard playlist.source == .appleMusic else { return }
        _ = run(AppleMusicScripts.reveal(playlistID: playlist.id))
    }

    /// Apple Music's queue isn't scriptable; returns the next tracks of the current playlist when possible.
    func upNext(limit: Int) -> [QueueItem] {
        guard limit > 0 else { return [] }
        return AppleMusicScripts.parseQueue(run(AppleMusicScripts.upNext(limit: limit)))
    }

    private var isMusicRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: PlayerSource.appleMusic.bundleIdentifier).isEmpty
    }

    /// The script's string result, or `nil` when Music isn't running or the script failed.
    private func run(_ source: String) -> String? {
        guard isMusicRunning, case .success(let descriptor) = runner.run(source) else { return nil }
        return descriptor.stringValue ?? ""
    }
}
