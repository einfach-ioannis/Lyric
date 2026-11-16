import Foundation

/// Parses the LRC format: `[mm:ss.xx] line`, with one or more timestamps per line. Word
/// timings of the enhanced format (`<mm:ss.xx> word`) are dropped.
nonisolated enum LRCParser {
    private static var lineTimestamp: Regex<(Substring, Substring, Substring)> { /\[(\d{1,3}):(\d{1,2}(?:[.:]\d{1,3})?)\]/ }
    private static var wordTimestamp: Regex<(Substring, Substring, Substring)> { /<(\d{1,3}):(\d{1,2}(?:[.:]\d{1,3})?)>/ }

    static func parse(_ lrc: String) -> [LyricLine] {
        var entries: [(time: TimeInterval, text: String)] = []

        for rawLine in lrc.split(whereSeparator: \.isNewline) {
            var remainder = Substring(rawLine)
            var times: [TimeInterval] = []

            while let match = remainder.prefixMatch(of: lineTimestamp) {
                times.append(seconds(match.output.1, match.output.2))
                remainder = remainder[match.range.upperBound...]
            }

            let text = remainder
                .replacing(wordTimestamp, with: "")
                .split(separator: " ", omittingEmptySubsequences: true)
                .joined(separator: " ")
            for time in times {
                entries.append((time, text))
            }
        }

        return entries
            .sorted { $0.time < $1.time }
            .enumerated()
            .map { LyricLine(id: $0.offset, time: $0.element.time, text: $0.element.text) }
    }

    static func plainLines(_ text: String) -> [LyricLine] {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .enumerated()
            .map { LyricLine(id: $0.offset, time: 0, text: $0.element.trimmingCharacters(in: .whitespaces)) }
    }

    private static func seconds(_ minutes: Substring, _ seconds: Substring) -> TimeInterval {
        (Double(minutes) ?? 0) * 60 + (Double(seconds.replacing(":", with: ".")) ?? 0)
    }
}
