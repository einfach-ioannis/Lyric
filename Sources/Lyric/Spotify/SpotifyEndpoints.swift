import Foundation

/// Fixed addresses, scopes and coding helpers for the Spotify Web API.
nonisolated enum SpotifyEndpoints {
    static let redirectURI = "lyric://spotify-callback"
    static let callbackScheme = "lyric"
    static let callbackHost = "spotify-callback"
    static let accountsHost = "accounts.spotify.com"
    static let apiHost = "api.spotify.com"

    static let scopes = [
        "user-library-read",
        "user-library-modify",
        "playlist-read-private",
        "playlist-read-collaborative",
        "user-read-playback-state",
        "user-read-currently-playing",
    ]

    /// `https://accounts.spotify.com/api/token`.
    static func tokenURL() throws(SpotifyError) -> URL {
        try url(host: accountsHost, path: "/api/token", query: [])
    }

    /// A Web API address such as `https://api.spotify.com/v1/me/tracks?ids=…`.
    static func apiURL(path: String, query: [URLQueryItem] = []) throws(SpotifyError) -> URL {
        try url(host: apiHost, path: "/v1/\(path)", query: query)
    }

    static func url(host: String, path: String, query: [URLQueryItem]) throws(SpotifyError) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else { throw .invalidRequest }
        return url
    }

    /// `application/x-www-form-urlencoded` body for the token endpoint.
    static func formBody(_ fields: KeyValuePairs<String, String>) -> Data {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let encoded = fields.map { key, value in
            let name = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
            let content = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
            return "\(name)=\(content)"
        }
        return Data(encoded.joined(separator: "&").utf8)
    }

    /// Decoder for Spotify's snake_case JSON.
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
