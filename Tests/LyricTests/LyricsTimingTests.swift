import Testing
@testable import Lyric

struct LyricsTimingTests {
    private let lyrics = Lyrics(
        lines: [
            LyricLine(id: 0, time: 5, text: "One"),
            LyricLine(id: 1, time: 10, text: "Two"),
            LyricLine(id: 2, time: 15, text: "Three"),
        ],
        isSynced: true
    )

    @Test(arguments: [
        (0.0, nil),
        (5.0, 0),
        (9.99, 0),
        (10.0, 1),
        (120.0, 2),
    ] as [(Double, Int?)])
    func findsCurrentLine(time: Double, expected: Int?) {
        #expect(lyrics.lineIndex(at: time) == expected)
    }

    @Test func unsyncedLyricsHaveNoCurrentLine() {
        let plain = Lyrics(lines: lyrics.lines, isSynced: false)
        #expect(plain.lineIndex(at: 12) == nil)
    }
}
