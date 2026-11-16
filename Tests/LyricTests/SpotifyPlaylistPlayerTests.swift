import Foundation
import Testing
@testable import Lyric

@MainActor
struct SpotifyPlaylistPlayerTests {
    @Test(arguments: [
        "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M",
        "spotify:user:listener:collection",
        #"weird "quoted" \ uri"#,
    ])
    func playScriptCompiles(uri: String) {
        var error: NSDictionary?
        let script = NSAppleScript(source: SpotifyPlaylistPlayer.script(forURI: uri))
        let compiled = script?.compileAndReturnError(&error) ?? false
        #expect(compiled, "\(error ?? [:])")
    }
}
