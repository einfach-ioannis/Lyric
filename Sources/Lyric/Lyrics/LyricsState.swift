import Foundation

nonisolated enum LyricsState: Equatable, Sendable {
    case idle
    case loading
    case loaded(Lyrics)
    case instrumental
    case unavailable
}
