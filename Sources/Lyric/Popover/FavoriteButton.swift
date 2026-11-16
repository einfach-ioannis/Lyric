import SwiftUI

/// Heart button for liking the current song. Hidden while the favorite state is unknown.
struct FavoriteButton: View {
    @Environment(LibraryController.self) private var library
    @Environment(NowPlayingController.self) private var nowPlaying

    var body: some View {
        if let isFavorite = library.isFavorite {
            Button(
                isFavorite ? LocalizedStringKey("Remove from Favorites") : "Add to Favorites",
                systemImage: isFavorite ? "heart.fill" : "heart",
                action: library.toggleFavorite
            )
            .labelStyle(.iconOnly)
            .font(.title3)
            .foregroundStyle(isFavorite ? Theme.Palette.heart : Color.white)
            .contentTransition(.symbolEffect(.replace))
            .buttonStyle(CircleButtonStyle())
            .help(isFavorite ? LocalizedStringKey("Remove from Favorites") : "Add to Favorites")
        }
    }
}
