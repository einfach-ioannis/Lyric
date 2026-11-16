import Foundation

/// One PKCE login: the secret verifier and the `state` the redirect must echo.
nonisolated struct SpotifyLoginAttempt: Equatable, Sendable {
    let verifier: String
    let state: String

    init(verifier: String = SpotifyPKCE.makeVerifier(), state: String = SpotifyPKCE.makeState()) {
        self.verifier = verifier
        self.state = state
    }

    /// The `https://accounts.spotify.com/authorize` page to open in the browser.
    func authorizeURL(clientID: String) throws(SpotifyError) -> URL {
        try SpotifyEndpoints.url(host: SpotifyEndpoints.accountsHost, path: "/authorize", query: [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: SpotifyEndpoints.redirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: SpotifyPKCE.challenge(for: verifier)),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: SpotifyEndpoints.scopes.joined(separator: " ")),
        ])
    }

    /// Pulls the authorization code out of `lyric://spotify-callback?code=…&state=…`.
    func authorizationCode(from url: URL) throws(SpotifyError) -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == SpotifyEndpoints.callbackScheme,
              components.host == SpotifyEndpoints.callbackHost
        else { throw .invalidCallback }

        let items = components.queryItems ?? []
        func value(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        guard value("state") == state else { throw .stateMismatch }
        if let error = value("error") {
            throw error == "access_denied" ? .accessDenied : .authorizationFailed(code: error, description: nil)
        }
        guard let code = value("code"), !code.isEmpty else { throw .invalidCallback }
        return code
    }
}
