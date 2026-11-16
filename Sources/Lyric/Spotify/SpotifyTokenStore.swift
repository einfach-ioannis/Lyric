import Foundation

/// Keeps the Spotify session in a private file in Application Support.
///
/// The login Keychain asked for the Mac password whenever the app's code signature changed,
/// so the session lives in a file readable only by the current user (permissions 0600).
nonisolated struct SpotifyTokenStore: Sendable {
    let fileURL: URL

    init(fileURL: URL = URL.applicationSupportDirectory.appending(path: "Lyric/spotify-session.json")) {
        self.fileURL = fileURL
    }

    func load() -> SpotifyTokens? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(SpotifyTokens.self, from: data)
    }

    func save(_ tokens: SpotifyTokens) throws(SpotifyError) {
        do {
            let data = try JSONEncoder().encode(tokens)
            let folder = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            try data.write(to: fileURL, options: [.atomic])
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path(percentEncoded: false))
        } catch {
            throw .storage
        }
    }

    func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
