import Testing
@testable import Lyric

@MainActor
struct MenuBarTruncationTests {
    @Test func keepsShortText() {
        #expect("Yellow".truncated(to: 40) == "Yellow")
    }

    @Test func cutsLongTextWithEllipsis() {
        let result = "Under the city lights we fade away".truncated(to: 10)
        #expect(result == "Under the…")
        #expect(result.count <= 10)
    }
}
