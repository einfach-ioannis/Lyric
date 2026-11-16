import AppKit

/// Talks to Music and Spotify through Apple Events.
///
/// `NSAppleScript` is only safe on the main thread, so every script carries a short
/// `with timeout` to keep a hung player from stalling the interface.
final class PlayerBridge {
    private let runner = AppleScriptRunner()

    func isRunning(_ source: PlayerSource) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: source.bundleIdentifier).isEmpty
    }

    func read(preferring preferred: PlayerSource?) -> PlaybackReading {
        var snapshots: [PlaybackSnapshot] = []
        var permissionDenied = false

        for source in PlayerSource.allCases where isRunning(source) {
            switch run(PlayerScripts.status(for: source)) {
            case .success(let descriptor):
                if let snapshot = PlayerScripts.parseStatus(descriptor.stringValue, source: source) {
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
        _ = run(PlayerScripts.command(command, for: source))
    }

    /// Embedded artwork from the Music library, when the track has any.
    func musicArtworkData() -> Data? {
        guard isRunning(.appleMusic), case .success(let descriptor) = run(PlayerScripts.musicArtwork) else {
            return nil
        }
        let data = descriptor.data
        return data.isEmpty ? nil : data
    }

    private func run(_ source: String) -> Result<NSAppleEventDescriptor, ScriptError> {
        runner.run(source)
    }
}
