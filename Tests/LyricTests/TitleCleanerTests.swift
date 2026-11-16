import Testing
@testable import Lyric

struct TitleCleanerTests {
    @Test(arguments: [
        ("Here Comes the Sun - Remastered 2009", "Here Comes the Sun"),
        ("Stay (feat. Justin Bieber)", "Stay"),
        ("Yellow", "Yellow"),
        ("Song [Live]", "Song"),
    ])
    func stripsDecorations(input: String, expected: String) {
        #expect(TitleCleaner.clean(input) == expected)
    }
}

struct TitleCleanerSoundtrackTests {
    @Test func stripsSoundtrackAndFeatureTags() {
        #expect(TitleCleaner.clean("Flower In A Hurricane (feat. Tame Impala, SZA) [From GTAVI: Original Score]") == "Flower In A Hurricane")
    }
}
