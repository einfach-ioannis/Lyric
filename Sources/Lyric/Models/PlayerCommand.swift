import Foundation

nonisolated enum PlayerCommand: Equatable, Sendable {
    case playPause
    case nextTrack
    case previousTrack
    case seek(TimeInterval)
    case setShuffle(Bool)
    case setRepeat(Bool)
    /// Output volume, 0...100.
    case setVolume(Int)

    /// The statement sent inside `tell application …`; property names differ per player.
    func scriptBody(for source: PlayerSource) -> String {
        switch self {
        case .playPause:
            "playpause"
        case .nextTrack:
            "next track"
        case .previousTrack:
            "previous track"
        case .seek(let position):
            "set player position to \(max(position, 0))"
        case .setShuffle(let enabled):
            switch source {
            case .appleMusic: "set shuffle enabled to \(enabled)"
            case .spotify: "set shuffling to \(enabled)"
            }
        case .setRepeat(let enabled):
            switch source {
            case .appleMusic: "set song repeat to \(enabled ? "all" : "off")"
            case .spotify: "set repeating to \(enabled)"
            }
        case .setVolume(let volume):
            "set sound volume to \(min(max(volume, 0), 100))"
        }
    }
}
