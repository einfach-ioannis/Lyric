import CryptoKit
import Foundation

/// Proof Key for Code Exchange (RFC 7636) helpers.
nonisolated enum SpotifyPKCE {
    /// A random 86-character verifier, within RFC 7636's 43–128 range.
    static func makeVerifier() -> String {
        base64URL(randomBytes(64))
    }

    /// A random value echoed back by the redirect to tie it to this login.
    static func makeState() -> String {
        base64URL(randomBytes(16))
    }

    /// `BASE64URL(SHA256(verifier))`, the `S256` code challenge.
    static func challenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return base64URL(digest.withUnsafeBytes { Data($0) })
    }

    static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacing("+", with: "-")
            .replacing("/", with: "_")
            .replacing("=", with: "")
    }

    private static func randomBytes(_ count: Int) -> Data {
        var generator = SystemRandomNumberGenerator()
        return Data((0..<count).map { _ in UInt8.random(in: .min ... .max, using: &generator) })
    }
}
