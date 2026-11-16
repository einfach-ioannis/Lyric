import Foundation

/// The outcome of asking the running players what they are doing.
nonisolated enum PlaybackReading: Equatable, Sendable {
    case snapshot(PlaybackSnapshot)
    case nothingPlaying
    case permissionDenied
}
