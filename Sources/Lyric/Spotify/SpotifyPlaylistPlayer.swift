import AppKit

/// Starts a Spotify context (playlist, album, Liked Songs) through AppleScript.
///
/// Unlike the Web API's play endpoint this works without Spotify Premium.
/// `NSAppleScript` must run on the main actor, which is this type's default isolation.
enum SpotifyPlaylistPlayer {
    static func script(forURI uri: String) -> String {
        let escaped = uri.replacing("\\", with: "\\\\").replacing("\"", with: "\\\"")
        return """
        with timeout of 2 seconds
            tell application "Spotify" to play track "\(escaped)"
        end timeout
        """
    }

    /// Returns whether Spotify accepted the command.
    @discardableResult
    static func play(uri: String) -> Bool {
        guard let script = NSAppleScript(source: script(forURI: uri)) else { return false }
        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)
        return errorInfo == nil
    }

    /// Shows a playlist (or Liked Songs) in the Spotify app.
    static func open(uri: String) {
        let target = uri.hasSuffix(":collection") ? "spotify:collection:tracks" : uri
        guard let url = URL(string: target) else { return }
        NSWorkspace.shared.open(url)
    }
}
