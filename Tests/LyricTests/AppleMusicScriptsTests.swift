import Testing
@testable import Lyric

struct AppleMusicScriptsTests {
    private let field = String(AppleMusicScripts.fieldSeparator)
    private let record = String(AppleMusicScripts.recordSeparator)

    @Test func parsesPlaylistRecords() {
        let output = [
            ["A1B2C3", "Road Trip", "86"].joined(separator: field),
            ["D4E5F6", "Single", "1"].joined(separator: field),
            ["", "Missing ID", "3"].joined(separator: field),
        ].joined(separator: record) + record

        let playlists = AppleMusicScripts.parsePlaylists(output)
        #expect(playlists == [
            PlaylistSummary(id: "A1B2C3", name: "Road Trip", detail: "86 songs", artworkURL: nil, source: .appleMusic),
            PlaylistSummary(id: "D4E5F6", name: "Single", detail: "1 song", artworkURL: nil, source: .appleMusic),
        ])
    }

    @Test func playlistNamesMayContainPunctuation() {
        let output = ["ID1", "Rock, Pop & \"More\"", "0"].joined(separator: field) + record
        #expect(AppleMusicScripts.parsePlaylists(output).first?.name == "Rock, Pop & \"More\"")
    }

    @Test func parsesQueueWithLocalisedDurations() {
        let output = [
            ["T1", "First", "Artist A", "174,576"].joined(separator: field),
            ["T2", "Second", "", "200"].joined(separator: field),
        ].joined(separator: record) + record

        let queue = AppleMusicScripts.parseQueue(output)
        #expect(queue.count == 2)
        #expect(queue.first?.duration == 174.576)
        #expect(queue.first?.artist == "Artist A")
        #expect(queue.last?.artist == "")
        #expect(queue.last?.duration == 200)
    }

    @Test func emptyOutputParsesToNothing() {
        #expect(AppleMusicScripts.parsePlaylists(nil).isEmpty)
        #expect(AppleMusicScripts.parsePlaylists("").isEmpty)
        #expect(AppleMusicScripts.parseQueue(nil).isEmpty)
        #expect(AppleMusicScripts.parseQueue("garbage").isEmpty)
    }

    @Test func parsesFavorite() {
        #expect(AppleMusicScripts.parseFavorite("true") == true)
        #expect(AppleMusicScripts.parseFavorite("false") == false)
        #expect(AppleMusicScripts.parseFavorite("") == nil)
        #expect(AppleMusicScripts.parseFavorite(nil) == nil)
    }

    @Test func escapesPlaylistIdentifiers() {
        #expect(AppleMusicScripts.escaped(#"a"b\c"#) == #"a\"b\\c"#)
        #expect(AppleMusicScripts.play(playlistID: #"x"y"#).contains(#"persistent ID is "x\"y""#))
    }
}
