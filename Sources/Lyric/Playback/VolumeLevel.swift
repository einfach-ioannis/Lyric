import Foundation

/// Volume arithmetic shared by the controller and its tests.
nonisolated enum VolumeLevel {
    static let range: ClosedRange<Double> = 0...100

    static func clamped(_ volume: Double) -> Double {
        guard volume.isFinite else { return range.lowerBound }
        return min(max(volume, range.lowerBound), range.upperBound)
    }

    /// The integer step the players accept.
    static func step(_ volume: Double) -> Int {
        Int(clamped(volume).rounded())
    }

    /// Whether moving from `old` to `new` changes the integer step and is worth sending.
    static func needsSend(from old: Double?, to new: Double) -> Bool {
        guard let old else { return true }
        return step(old) != step(new)
    }
}
