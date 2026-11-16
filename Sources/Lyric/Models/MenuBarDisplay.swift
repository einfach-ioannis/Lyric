import Foundation

/// What the menu bar item shows.
nonisolated enum MenuBarDisplay: String, CaseIterable, Identifiable, Sendable {
    /// An animated level meter on its own.
    case iconOnly
    /// Just the cover art, slightly larger, with no text.
    case artworkOnly
    /// The level meter followed by the song title.
    case title
    /// A small cover followed by "Artist — Title".
    case artworkAndArtist
    /// A small cover followed by the line being sung, falling back to the title.
    case lyrics
    /// Previous, play/pause and next buttons followed by the title.
    case inlineControls

    var id: Self { self }

    var localizedName: String {
        switch self {
        case .iconOnly: String(localized: "Icon Only")
        case .artworkOnly: String(localized: "Cover Art Only")
        case .title: String(localized: "Song Title")
        case .artworkAndArtist: String(localized: "Artwork and Artist")
        case .lyrics: String(localized: "Live Lyrics")
        case .inlineControls: String(localized: "Playback Controls")
        }
    }
}
