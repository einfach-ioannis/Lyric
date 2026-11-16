import Testing
@testable import Lyric

struct SpotifyTrackIDTests {
    @Test func extractsBareIDFromLyricTrackID() {
        #expect(SpotifyTrackID.bareID(fromTrackID: "spotify:spotify:track:6YJrz5WxB02vFvZZoZFK9t") == "6YJrz5WxB02vFvZZoZFK9t")
    }

    @Test func acceptsPlainSpotifyURI() {
        #expect(SpotifyTrackID.bareID(fromTrackID: "spotify:track:6YJrz5WxB02vFvZZoZFK9t") == "6YJrz5WxB02vFvZZoZFK9t")
    }

    @Test(arguments: [
        "spotify:spotify:local:Artist:Album:Title:215",
        "spotify:spotify:episode:4rOoJ6Egrf8K2IrywzwOMk",
        "spotify:Title|Artist|Album",
        "spotify:spotify:track:",
        "",
    ])
    func rejectsNonTrackIDs(trackID: String) {
        #expect(SpotifyTrackID.bareID(fromTrackID: trackID) == nil)
    }
}
