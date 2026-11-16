import Testing
@testable import Lyric

struct PlayerScriptsTests {
    private let sep = String(PlayerScripts.separator)
    private let base = ["playing", "Title", "Artist", "Album", "215,4", "12,5", "spotify:track:1", "https://i.scdn.co/image/abc"]

    @Test func parsesSpotifyStatusWithLocalisedDecimals() throws {
        let output = base.joined(separator: sep)
        let snapshot = try #require(PlayerScripts.parseStatus(output, source: .spotify))
        #expect(snapshot.isPlaying)
        #expect(snapshot.position == 12.5)
        #expect(snapshot.track.duration == 215.4)
        #expect(snapshot.track.id == "spotify:spotify:track:1")
        #expect(snapshot.track.artworkURL != nil)
    }

    @Test func oldEightFieldOutputHasNoModes() throws {
        let snapshot = try #require(PlayerScripts.parseStatus(base.joined(separator: sep), source: .spotify))
        #expect(snapshot.isShuffling == nil)
        #expect(snapshot.isRepeating == nil)
        #expect(snapshot.volume == nil)
    }

    @Test func parsesSpotifyModes() throws {
        let output = (base + ["true", "false", "64"]).joined(separator: sep)
        let snapshot = try #require(PlayerScripts.parseStatus(output, source: .spotify))
        #expect(snapshot.isShuffling == true)
        #expect(snapshot.isRepeating == false)
        #expect(snapshot.volume == 64)
    }

    @Test(arguments: [("off", false), ("one", true), ("all", true)])
    func parsesMusicRepeatModes(mode: String, expected: Bool) throws {
        let output = (base + ["false", mode, "37,5"]).joined(separator: sep)
        let snapshot = try #require(PlayerScripts.parseStatus(output, source: .appleMusic))
        #expect(snapshot.isShuffling == false)
        #expect(snapshot.isRepeating == expected)
        #expect(snapshot.volume == 37.5)
    }

    @Test func emptyOrUnknownModesAreNil() throws {
        let output = (base + ["", "maybe", ""]).joined(separator: sep)
        let snapshot = try #require(PlayerScripts.parseStatus(output, source: .appleMusic))
        #expect(snapshot.isShuffling == nil)
        #expect(snapshot.isRepeating == nil)
        #expect(snapshot.volume == nil)
    }

    @Test func parsesRawRepeatConstants() throws {
        let off = (base + ["false", "«constant ****kRpO»", "50"]).joined(separator: sep)
        let one = (base + ["false", "«constant ****kRp1»", "50"]).joined(separator: sep)
        #expect(try #require(PlayerScripts.parseStatus(off, source: .appleMusic)).isRepeating == false)
        #expect(try #require(PlayerScripts.parseStatus(one, source: .appleMusic)).isRepeating == true)
    }

    @Test func outOfRangeVolumeIsClamped() throws {
        let output = (base + ["true", "true", "140"]).joined(separator: sep)
        let snapshot = try #require(PlayerScripts.parseStatus(output, source: .spotify))
        #expect(snapshot.volume == 100)
    }

    @Test func stoppedPlayerHasNoSnapshot() {
        #expect(PlayerScripts.parseStatus("stopped", source: .appleMusic) == nil)
    }

    @Test func fallsBackToMetadataIdentifier() throws {
        let output = ["paused", "Title", "Artist", "Album", "200", "3", "", ""].joined(separator: sep)
        let snapshot = try #require(PlayerScripts.parseStatus(output, source: .appleMusic))
        #expect(!snapshot.isPlaying)
        #expect(snapshot.track.id == "appleMusic:Title|Artist|Album")
    }

    @Test func commandBodiesDifferPerSource() {
        #expect(PlayerCommand.setShuffle(true).scriptBody(for: .appleMusic) == "set shuffle enabled to true")
        #expect(PlayerCommand.setShuffle(false).scriptBody(for: .spotify) == "set shuffling to false")
        #expect(PlayerCommand.setRepeat(true).scriptBody(for: .appleMusic) == "set song repeat to all")
        #expect(PlayerCommand.setRepeat(false).scriptBody(for: .appleMusic) == "set song repeat to off")
        #expect(PlayerCommand.setRepeat(true).scriptBody(for: .spotify) == "set repeating to true")
        #expect(PlayerCommand.setVolume(150).scriptBody(for: .spotify) == "set sound volume to 100")
        #expect(PlayerCommand.setVolume(-3).scriptBody(for: .appleMusic) == "set sound volume to 0")
    }
}
