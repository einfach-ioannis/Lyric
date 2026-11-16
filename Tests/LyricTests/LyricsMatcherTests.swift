import Foundation
import Testing
@testable import Lyric

struct LyricsMatcherTests {
    private let track = Track(
        id: "spotify:x", title: "Mille vies", artist: "Colt", album: "Mille vies",
        duration: 235.8, source: .spotify, artworkURL: nil
    )

    @Test func acceptsCloseDurationRegardlessOfNames() {
        #expect(LyricsMatcher.accepts(title: "Other", artist: "Someone", durationDistance: 3, for: track))
    }

    @Test func acceptsDifferentCutWhenTitleAndArtistMatch() {
        #expect(LyricsMatcher.accepts(title: "Mille Vies", artist: "colt", durationDistance: 9.2, for: track))
    }

    @Test func rejectsDifferentCutOfAnotherSong() {
        #expect(!LyricsMatcher.accepts(title: "Scooter", artist: "Colt", durationDistance: 9.2, for: track))
    }

    @Test func rejectsVeryDifferentLength() {
        #expect(!LyricsMatcher.accepts(title: "Mille vies", artist: "Colt", durationDistance: 45, for: track))
    }
}

@Suite struct LyricsConsensusTests {
    private func upload(chorus: String, shift: Double = 0) -> [LyricLine] {
        LRCParser.parse("""
        [01:05.00]Only love never hesitates
        [01:20.00]Only love never hesitates
        \(chorus)Let's take it fast
        [02:10.00]And in a moment
        """).map { LyricLine(id: $0.id, time: $0.time + shift, text: $0.text) }
    }

    @Test func fixesTheOneLineTheOthersDisagreeWith() {
        let base = upload(chorus: "[01:53.50]")
        let others = [upload(chorus: "[02:06.00]"), upload(chorus: "[02:05.60]", shift: 0.4), upload(chorus: "[02:06.00]", shift: -0.3)]
        let fixed = LyricsConsensus.corrected(base, using: others)
        let line = fixed.first { $0.text == "Let's take it fast" }!
        #expect(abs(line.time - 126) < 0.5)
        #expect(fixed.first!.time == 65)
    }

    @Test func leavesAgreeingLyricsAlone() {
        let base = upload(chorus: "[02:06.00]")
        #expect(LyricsConsensus.corrected(base, using: [upload(chorus: "[02:06.20]"), upload(chorus: "[02:05.90]"), upload(chorus: "[01:50.00]")]) == base)
    }

    @Test func needsEnoughVoters() {
        let base = upload(chorus: "[01:53.50]")
        #expect(LyricsConsensus.corrected(base, using: [upload(chorus: "[02:06.00]")]) == base)
    }
}
