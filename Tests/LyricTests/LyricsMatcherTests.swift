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
