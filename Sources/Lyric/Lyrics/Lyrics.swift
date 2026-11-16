import Foundation

nonisolated struct Lyrics: Equatable, Sendable {
    let lines: [LyricLine]
    let isSynced: Bool

    /// The index of the line being sung at `time`, found with a binary search.
    func lineIndex(at time: TimeInterval) -> Int? {
        guard isSynced, let first = lines.first, time >= first.time else { return nil }
        var low = 0
        var high = lines.count - 1
        while low < high {
            let middle = (low + high + 1) / 2
            if lines[middle].time <= time {
                low = middle
            } else {
                high = middle - 1
            }
        }
        return low
    }
}
