import Foundation

/// A single reading of a player's state.
nonisolated struct PlaybackSnapshot: Equatable, Sendable {
    let track: Track
    let isPlaying: Bool
    let position: TimeInterval
    /// Shuffle, repeat and volume (0...100); `nil` when the player didn't report them.
    let isShuffling: Bool?
    let isRepeating: Bool?
    let volume: Double?

    init(
        track: Track,
        isPlaying: Bool,
        position: TimeInterval,
        isShuffling: Bool? = nil,
        isRepeating: Bool? = nil,
        volume: Double? = nil
    ) {
        self.track = track
        self.isPlaying = isPlaying
        self.position = position
        self.isShuffling = isShuffling
        self.isRepeating = isRepeating
        self.volume = volume
    }
}
