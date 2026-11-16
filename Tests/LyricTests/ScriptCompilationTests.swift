import Foundation
import Testing
@testable import Lyric

/// Compiling needs no running player, so this catches syntax slips such as reserved words.
@MainActor
struct ScriptCompilationTests {
    private static let commands: [PlayerCommand] = [
        .playPause, .nextTrack, .previousTrack, .seek(12.5),
        .setShuffle(true), .setShuffle(false),
        .setRepeat(true), .setRepeat(false),
        .setVolume(0), .setVolume(42), .setVolume(100),
    ]

    @Test(arguments: PlayerSource.allCases)
    func statusScriptCompiles(source: PlayerSource) {
        expectCompiles(PlayerScripts.status(for: source))
    }

    @Test(arguments: PlayerSource.allCases)
    func commandScriptsCompile(source: PlayerSource) {
        for command in Self.commands {
            expectCompiles(PlayerScripts.command(command, for: source))
        }
    }

    @Test func artworkScriptCompiles() {
        expectCompiles(PlayerScripts.musicArtwork)
    }

    @Test func libraryScriptsCompile() {
        expectCompiles(AppleMusicScripts.currentTrackFavorite)
        expectCompiles(AppleMusicScripts.setCurrentTrackFavorite(true))
        expectCompiles(AppleMusicScripts.setCurrentTrackFavorite(false))
        expectCompiles(AppleMusicScripts.playlists)
        expectCompiles(AppleMusicScripts.play(playlistID: "ABCDEF0123456789"))
        expectCompiles(AppleMusicScripts.play(playlistID: "odd \"quoted\" \\ id"))
        expectCompiles(AppleMusicScripts.upNext(limit: 10))
        expectCompiles(AppleMusicScripts.upNext(limit: 0))
    }

    private func expectCompiles(_ source: String) {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        let compiled = script?.compileAndReturnError(&error) ?? false
        #expect(compiled, "\(error ?? [:])\n\(source)")
    }
}
