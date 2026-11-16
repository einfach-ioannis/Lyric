import Foundation

/// Adds instrumental breaks where the lyrics don't mark them, so the highlight leaves a line
/// once it has been sung instead of lingering through a long instrumental part.
nonisolated enum LyricBreaks {
    /// An intro at least this long gets a break before the first line.
    static let minimumIntro: TimeInterval = 5
    /// A gap at least this long after a line has been sung becomes a break.
    static let minimumGap: TimeInterval = 5

    static func inserting(into lines: [LyricLine]) -> [LyricLine] {
        guard let first = lines.first else { return lines }
        var result: [(time: TimeInterval, text: String)] = []

        if !first.isBreak, first.time >= minimumIntro {
            result.append((0, ""))
        }
        for (index, line) in lines.enumerated() {
            result.append((line.time, line.text))
            guard !line.isBreak, index + 1 < lines.count, !lines[index + 1].isBreak else { continue }
            let sungUntil = line.time + singingTime(of: line.text)
            if lines[index + 1].time - sungUntil >= minimumGap {
                result.append((sungUntil, ""))
            }
        }
        return result.enumerated().map { LyricLine(id: $0.offset, time: $0.element.time, text: $0.element.text) }
    }

    /// A generous guess of how long a line takes to sing, held notes included, so a break
    /// only appears where the music clearly carries on alone.
    static func singingTime(of text: String) -> TimeInterval {
        let words = text.split(separator: " ").count
        return min(max(Double(words) * 0.6 + 1.5, 3), 8)
    }
}
