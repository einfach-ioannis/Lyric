import Testing
@testable import Lyric

struct LRCParserTests {
    @Test func parsesTimestampsInOrder() {
        let lines = LRCParser.parse("""
        [00:12.50]Second line
        [00:01.00]First line
        [01:02.3]Third line
        """)
        #expect(lines.map(\.text) == ["First line", "Second line", "Third line"])
        #expect(lines.map(\.time) == [1, 12.5, 62.3])
        #expect(lines.map(\.id) == [0, 1, 2])
    }

    @Test func expandsRepeatedTimestamps() {
        let lines = LRCParser.parse("[00:05.00][00:30.00]Chorus")
        #expect(lines.count == 2)
        #expect(lines.allSatisfy { $0.text == "Chorus" })
    }

    @Test func keepsEmptyLinesAsBreaks() {
        let lines = LRCParser.parse("[00:05.00]\n[00:09.00]Back again")
        #expect(lines.first?.isBreak == true)
    }

    @Test func ignoresMetadataTags() {
        let lines = LRCParser.parse("[ar:Artist]\n[ti:Title]\n[00:01.00]Hello")
        #expect(lines.map(\.text) == ["Hello"])
    }
}
