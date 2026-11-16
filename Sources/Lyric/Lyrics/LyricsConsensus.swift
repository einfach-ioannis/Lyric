import Foundation

/// Fixes single badly timed lines using other uploads of the same song.
///
/// LRCLIB often holds many uploads of one song. The one closest in length to the song
/// playing is usually right, but now and then a single line in it is seconds off. When most
/// of the other uploads agree that line belongs elsewhere (relative to their own overall
/// offset, since a different cut can shift everything), it's moved there.
nonisolated enum LyricsConsensus {
    /// A line is only moved when the others put it at least this far away…
    private static let minimumCorrection: TimeInterval = 2
    /// …at least this many of them have the line…
    private static let minimumVoters = 3
    /// …and this share of those agree with each other.
    private static let requiredAgreement = 0.6
    private static let agreementWindow: TimeInterval = 1.5

    /// Lines count as the same when they share this much of their words, so small
    /// transcription differences ("like a flash" / "like the Flash") still match.
    private static let minimumSimilarity = 0.6

    private struct Entry {
        let time: TimeInterval
        let words: Set<String>
    }

    static func corrected(_ base: [LyricLine], using others: [[LyricLine]]) -> [LyricLine] {
        guard others.count >= minimumVoters else { return base }
        let baseEntries = base.map(entry)
        let otherEntries = others.map { $0.filter { !$0.isBreak }.map(entry) }

        // How much each other upload is shifted overall against this one.
        let offsets = otherEntries.map { entries in
            median(baseEntries.compactMap { line in
                match(line, in: entries, near: line.time).map { $0 - line.time }
            }) ?? 0
        }

        var lines = base
        for (index, line) in base.enumerated() where !line.isBreak {
            let deviations = otherEntries.indices.compactMap { other -> Double? in
                let expected = line.time + offsets[other]
                return match(baseEntries[index], in: otherEntries[other], near: expected).map { $0 - expected }
            }
            guard deviations.count >= minimumVoters, let correction = median(deviations),
                  abs(correction) >= minimumCorrection else { continue }
            let agreeing = deviations.filter { abs($0 - correction) <= agreementWindow }.count
            guard Double(agreeing) >= Double(deviations.count) * requiredAgreement else { continue }

            lines[index] = LyricLine(id: line.id, time: line.time + correction, text: line.text)
        }
        return lines
    }

    /// The time of the line in `entries` most like `line`, picking the one nearest `time`
    /// when the line is repeated.
    private static func match(_ line: Entry, in entries: [Entry], near time: TimeInterval) -> TimeInterval? {
        guard !line.words.isEmpty else { return nil }
        return entries
            .filter { similarity(line.words, $0.words) >= minimumSimilarity }
            .min { abs($0.time - time) < abs($1.time - time) }?
            .time
    }

    private static func similarity(_ lhs: Set<String>, _ rhs: Set<String>) -> Double {
        let union = lhs.union(rhs).count
        return union == 0 ? 0 : Double(lhs.intersection(rhs).count) / Double(union)
    }

    private static func entry(_ line: LyricLine) -> Entry {
        let words = line.text.lowercased()
            .split { !$0.isLetter && !$0.isNumber && $0 != "'" }
            .map { String($0).replacing("'", with: "") }
        return Entry(time: line.time, words: Set(words))
    }

    private static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}
