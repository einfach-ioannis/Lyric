import SwiftUI

/// Shared design constants so every surface of Lyric feels like one product.
enum Theme {
    enum Spacing {
        static let hairline = 2.0
        static let tight = 4.0
        static let compact = 6.0
        static let small = 8.0
        static let regular = 10.0
        static let medium = 12.0
        static let section = 14.0
        static let large = 16.0
        static let popoverInset = 18.0
        static let extraLarge = 22.0
    }

    enum Radius {
        static let artworkTiny = 3.5
        static let artworkSmall = 6.0
        static let artwork = 10.0
        static let card = 10.0
        static let row = 8.0
    }

    enum Typography {
        static let trackTitle = Font.title3.weight(.semibold)
    }

    enum Palette {
        /// The big play button is a white disc with a near-black glyph, as in Music.
        static let playButtonFill = Color.white
        static let playButtonGlyph = Color(white: 0.08)
        static let heart = Color(red: 1.0, green: 0.3, blue: 0.42)
        static let spotify = Color(red: 0.12, green: 0.84, blue: 0.38)
        static let appleMusic = Color(red: 0.98, green: 0.18, blue: 0.29)
        /// Darkens the popover material so the artwork wash reads like the mockup.
        static let popoverTint = Color.black.opacity(0.18)
    }

    enum Motion {
        static let lyric = Animation.smooth(duration: 0.45)
        static let quick = Animation.snappy(duration: 0.2)
        static let menuBarLine = Animation.smooth(duration: 0.35)
        static let backdrop = Animation.smooth(duration: 0.6)
        static let pressedScale = 0.9
    }

    enum Popover {
        /// How much smaller lines that aren't being sung are drawn.
        static let inactiveLyricScale = 0.86
        static let width = 340.0
        static let artworkSize = 64.0
        static let contentHeight = 250.0
        static let playButtonSize = 56.0
        static let circleButtonSize = 36.0
        static let transportButtonSize = 44.0
        static let queueArtworkSize = 36.0
        static let playlistArtworkSize = 40.0
        static let sourceDotSize = 8.0
        static let accentWashOpacity = 0.32
        static let artworkBlurOpacity = 0.55
    }

    enum MenuBar {
        static let maximumWidth = 320.0
        static let maximumTextLength = 40
        /// Kept below the 16 pt system icon size so cover art never looks heavier than
        /// the menu bar's other items.
        static let artworkSize = 14.0
        static let largeArtworkSize = 16.0
        static let meterHeight = 12.0
        static let controlSize = 20.0
        static let horizontalPadding = 5.0
        static let minimumWidth = 28.0
        static let highlightHeight = 20.0
    }
}
