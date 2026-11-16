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

@Suite struct LRCEnhancedTests {
    @Test func dropsWordTimings() {
        let line = LRCParser.parse("[00:10.00]<00:10.00> Hello <00:10.80> big <00:11.50> world")[0]
        #expect(line.text == "Hello big world")
        #expect(line.time == 10)
    }
}

@Suite struct LyricBreaksTests {
    @Test func addsIntroAndGapBreaks() {
        let lines = LyricBreaks.inserting(into: LRCParser.parse("""
        [00:12.00]First line here
        [00:15.00]Second line
        [00:40.00]After the solo
        """))
        #expect(lines.map(\.isBreak) == [true, false, false, true, false])
        #expect(lines[0].time == 0)
        #expect(lines[3].time > 15 && lines[3].time < 22)
        #expect(lines.map(\.id) == Array(0..<5))
    }

    @Test func keepsExistingBreaksAndShortGaps() {
        let lines = LRCParser.parse("[00:01.00]One\n[00:03.00]Two\n[00:05.00]\n[00:30.00]Three")
        #expect(LyricBreaks.inserting(into: lines) == lines)
    }
}
