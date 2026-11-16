import Foundation

/// Talks to the Spotify Web API on the person's behalf, refreshing the access token as needed.
actor SpotifyAPIClient {
    private let session: URLSession
    private let store: SpotifyTokenStore
    private var tokens: SpotifyTokens?
    private var refreshTask: Task<SpotifyTokens, any Error>?

    init(tokens: SpotifyTokens?, store: SpotifyTokenStore) {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["User-Agent": "Lyric/1.0 (macOS)"]
        configuration.timeoutIntervalForRequest = 10
        session = URLSession(configuration: configuration)
        self.store = store
        self.tokens = tokens
    }

    // MARK: - Session

    /// Exchanges the authorization code from the redirect, loads the profile and saves the session.
    func connect(code: String, verifier: String, clientID: String) async throws -> SpotifyTokens {
        let response = try await requestToken(fields: [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": SpotifyEndpoints.redirectURI,
            "client_id": clientID,
            "code_verifier": verifier,
        ])
        guard let refreshToken = response.refreshToken else { throw SpotifyError.invalidResponse }

        var newTokens = SpotifyTokens(
            accessToken: response.accessToken,
            refreshToken: refreshToken,
            expiry: .now.addingTimeInterval(TimeInterval(response.expiresIn)),
            displayName: "",
            userID: "",
            clientID: clientID
        )
        tokens = newTokens

        do {
            let profile: SpotifyUserProfile = try await getJSON(path: "me")
            newTokens.userID = profile.id
            newTokens.displayName = profile.displayName.flatMap { $0.isEmpty ? nil : $0 } ?? profile.id
            tokens = newTokens
            try store.save(newTokens)
            return newTokens
        } catch {
            tokens = nil
            throw error
        }
    }

    func signOut() {
        refreshTask?.cancel()
        refreshTask = nil
        tokens = nil
        store.delete()
    }

    // MARK: - Library

    func isSaved(trackID: String) async throws -> Bool {
        let flags: [Bool] = try await getJSON(path: "me/tracks/contains", query: [URLQueryItem(name: "ids", value: trackID)])
        return flags.first ?? false
    }

    func setSaved(_ saved: Bool, trackID: String) async throws {
        let body = try JSONEncoder().encode(["ids": [trackID]])
        let (_, response) = try await send(
            method: saved ? "PUT" : "DELETE",
            path: "me/tracks",
            query: [URLQueryItem(name: "ids", value: trackID)],
            jsonBody: body
        )
        try Self.expectSuccess(response)
    }

    /// "Liked Songs" plus the first 50 of the person's playlists.
    func playlists() async throws -> [PlaylistSummary] {
        let page: SpotifyPlaylistPage = try await getJSON(path: "me/playlists", query: [URLQueryItem(name: "limit", value: "50")])
        let liked: SpotifyTotal? = try? await getJSON(path: "me/tracks", query: [URLQueryItem(name: "limit", value: "1")])
        return page.summaries(userID: tokens?.userID ?? "", likedSongCount: liked?.total)
    }

    /// Upcoming songs; empty when nothing is playing or the queue isn't available.
    func queue() async throws -> [QueueItem] {
        let (data, response) = try await send(method: "GET", path: "me/player/queue")
        switch response.statusCode {
        case 204, 403, 404:
            return []
        default:
            try Self.expectSuccess(response)
            return try Self.decode(SpotifyQueueResponse.self, from: data).items()
        }
    }

    // MARK: - Requests

    private func getJSON<Value: Decodable>(path: String, query: [URLQueryItem] = []) async throws -> Value {
        let (data, response) = try await send(method: "GET", path: path, query: query)
        try Self.expectSuccess(response)
        return try Self.decode(Value.self, from: data)
    }

    /// Sends an authorized request, refreshing once on 401 and waiting once on 429.
    private func send(
        method: String,
        path: String,
        query: [URLQueryItem] = [],
        jsonBody: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let url = try SpotifyEndpoints.apiURL(path: path, query: query)
        var retriedAuthorization = false
        var retriedRateLimit = false

        while true {
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.setValue("Bearer \(try await accessToken())", forHTTPHeaderField: "Authorization")
            if let jsonBody {
                request.httpBody = jsonBody
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }

            let (data, response) = try await perform(request)
            switch response.statusCode {
            case 401 where !retriedAuthorization:
                retriedAuthorization = true
                _ = try await refreshedTokens()
            case 429 where !retriedRateLimit:
                retriedRateLimit = true
                try await Task.sleep(for: .seconds(Self.retryDelay(response)))
            case 429:
                throw SpotifyError.rateLimited
            default:
                return (data, response)
            }
        }
    }

    private func accessToken() async throws -> String {
        guard let tokens else { throw SpotifyError.notSignedIn }
        if tokens.needsRefresh() {
            return try await refreshedTokens().accessToken
        }
        return tokens.accessToken
    }

    /// Refreshes the access token, sharing one refresh between concurrent callers.
    private func refreshedTokens() async throws -> SpotifyTokens {
        if let refreshTask {
            return try await refreshTask.value
        }
        guard let current = tokens else { throw SpotifyError.notSignedIn }

        let task = Task { try await self.refresh(current) }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    private func refresh(_ current: SpotifyTokens) async throws -> SpotifyTokens {
        let response: SpotifyTokenResponse
        do {
            response = try await requestToken(fields: [
                "grant_type": "refresh_token",
                "refresh_token": current.refreshToken,
                "client_id": current.clientID,
            ])
        } catch SpotifyError.authorizationFailed {
            tokens = nil
            store.delete()
            throw SpotifyError.sessionExpired
        }

        // Signed out while the refresh was in flight.
        guard tokens?.refreshToken == current.refreshToken else { throw SpotifyError.notSignedIn }

        var updated = current
        updated.accessToken = response.accessToken
        updated.refreshToken = response.refreshToken ?? current.refreshToken
        updated.expiry = .now.addingTimeInterval(TimeInterval(response.expiresIn))
        tokens = updated
        // A storage hiccup shouldn’t end a working session; the next launch refreshes again.
        try? store.save(updated)
        return updated
    }

    private func requestToken(fields: KeyValuePairs<String, String>) async throws -> SpotifyTokenResponse {
        var request = URLRequest(url: try SpotifyEndpoints.tokenURL())
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = SpotifyEndpoints.formBody(fields)

        let (data, response) = try await perform(request)
        if (400..<500).contains(response.statusCode),
           let failure = try? SpotifyEndpoints.decoder().decode(SpotifyAuthErrorResponse.self, from: data) {
            throw SpotifyError.authorizationFailed(code: failure.error, description: failure.errorDescription)
        }
        if response.statusCode == 429 {
            throw SpotifyError.rateLimited
        }
        try Self.expectSuccess(response)
        return try Self.decode(SpotifyTokenResponse.self, from: data)
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw SpotifyError.network(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else { throw SpotifyError.invalidResponse }
        return (data, http)
    }

    // MARK: - Helpers

    private static func expectSuccess(_ response: HTTPURLResponse) throws {
        guard (200..<300).contains(response.statusCode) else {
            throw SpotifyError.http(status: response.statusCode)
        }
    }

    private static func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        do {
            return try SpotifyEndpoints.decoder().decode(type, from: data)
        } catch {
            throw SpotifyError.invalidResponse
        }
    }

    /// Seconds from `Retry-After`, kept between 1 and 30.
    private static func retryDelay(_ response: HTTPURLResponse) -> Int {
        let seconds = response.value(forHTTPHeaderField: "Retry-After").flatMap { Int($0) } ?? 1
        return min(max(seconds, 1), 30)
    }
}
