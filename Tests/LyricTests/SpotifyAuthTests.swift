import Foundation
import Testing
@testable import Lyric

struct SpotifyAuthTests {
    @Test func challengeMatchesRFC7636Vector() {
        let challenge = SpotifyPKCE.challenge(for: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        #expect(challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    @Test func verifierIsURLSafeAndLongEnough() {
        let verifier = SpotifyPKCE.makeVerifier()
        #expect((43...128).contains(verifier.count))
        #expect(verifier.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" })
        #expect(SpotifyPKCE.makeVerifier() != verifier)
    }

    @Test func authorizeURLCarriesPKCEParameters() throws {
        let attempt = SpotifyLoginAttempt(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk", state: "xyz")
        let url = try attempt.authorizeURL(clientID: "abc123")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.host == "accounts.spotify.com")
        #expect(components.path == "/authorize")

        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(items["client_id"] == "abc123")
        #expect(items["response_type"] == "code")
        #expect(items["redirect_uri"] == "lyric://spotify-callback")
        #expect(items["code_challenge_method"] == "S256")
        #expect(items["code_challenge"] == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
        #expect(items["state"] == "xyz")
        #expect(items["scope"] == "user-library-read user-library-modify playlist-read-private playlist-read-collaborative user-read-playback-state user-read-currently-playing")
    }

    @Test func callbackYieldsCodeWhenStateMatches() throws {
        let attempt = SpotifyLoginAttempt(verifier: "v", state: "s1")
        let url = try #require(URL(string: "lyric://spotify-callback?code=AQB42&state=s1"))
        #expect(try attempt.authorizationCode(from: url) == "AQB42")
    }

    @Test func callbackRejectsWrongState() throws {
        let attempt = SpotifyLoginAttempt(verifier: "v", state: "s1")
        let url = try #require(URL(string: "lyric://spotify-callback?code=AQB42&state=other"))
        #expect(throws: SpotifyError.stateMismatch) { try attempt.authorizationCode(from: url) }
    }

    @Test func callbackReportsDeclinedAccess() throws {
        let attempt = SpotifyLoginAttempt(verifier: "v", state: "s1")
        let url = try #require(URL(string: "lyric://spotify-callback?error=access_denied&state=s1"))
        #expect(throws: SpotifyError.accessDenied) { try attempt.authorizationCode(from: url) }
    }
}
