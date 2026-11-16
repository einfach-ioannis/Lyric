import Foundation

nonisolated struct LyricLine: Identifiable, Equatable, Sendable {
    let id: Int
    let time: TimeInterval
    let text: String

    /// Empty synced lines mark instrumental breaks.
    var isBreak: Bool { text.isEmpty }
}
