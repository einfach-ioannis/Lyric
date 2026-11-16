import AppKit

/// Talks to Music and Spotify through Apple Events.
///
/// Scripts run off the main thread (see `AppleScriptRunner`), so reading the player never
/// stalls the interface; commands are queued and run in order.
final class PlayerBridge {
    private let runner = AppleScriptRunner()

    func isRunning(_ source: PlayerSource) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: source.bundleIdentifier).isEmpty
    }

    func read(preferring preferred: PlayerSource?) async -> PlaybackReading {
        var snapshots: [PlaybackSnapshot] = []
        var permissionDenied = false

        for source in PlayerSource.allCases where isRunning(source) {
            switch await runner.run(PlayerScripts.status(for: source)) {
            case .success(let output):
                if let snapshot = PlayerScripts.parseStatus(output.string, source: source) {
                    snapshots.append(snapshot)
                }
            case .failure(let error):
                permissionDenied = permissionDenied || error.isPermissionDenied
            }
        }

        if let playing = snapshots.first(where: \.isPlaying) {
            return .snapshot(playing)
        }
        if let paused = snapshots.first(where: { $0.track.source == preferred }) ?? snapshots.first {
            return .snapshot(paused)
        }
        return permissionDenied ? .permissionDenied : .nothingPlaying
    }

    func send(_ command: PlayerCommand, to source: PlayerSource) {
        guard isRunning(source) else { return }
        runner.enqueue(PlayerScripts.command(command, for: source))
    }

    /// Embedded artwork from the Music library, when the track has any.
    func musicArtworkData() async -> Data? {
        guard isRunning(.appleMusic), case .success(let output) = await runner.run(PlayerScripts.musicArtwork) else {
            return nil
        }
        let data = output.data
        return data.isEmpty ? nil : data
    }
}
