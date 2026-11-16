import Foundation

/// Parses the LRC format: `[mm:ss.xx] line`, with one or more timestamps per line.
nonisolated enum LRCParser {
    static func parse(_ lrc: String) -> [LyricLine] {
        let timestamp = /\[(\d{1,3}):(\d{1,2}(?:[.:]\d{1,3})?)\]/
        var entries: [(time: TimeInterval, text: String)] = []

        for rawLine in lrc.split(whereSeparator: \.isNewline) {
            var remainder = Substring(rawLine)
            var times: [TimeInterval] = []

            while let match = remainder.prefixMatch(of: timestamp) {
                let minutes = Double(match.output.1) ?? 0
                let seconds = Double(match.output.2.replacing(":", with: ".")) ?? 0
                times.append(minutes * 60 + seconds)
                remainder = remainder[match.range.upperBound...]
            }

            let text = remainder.trimmingCharacters(in: .whitespaces)
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
}
