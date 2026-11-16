import Foundation

/// Downloads cover art, falling back to the public iTunes Search API for streamed tracks.
nonisolated enum ArtworkFetcher {
    @concurrent
    static func download(_ url: URL) async -> Data? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200, !data.isEmpty else { return nil }
            return data
        } catch {
            return nil
        }
    }

    @concurrent
    static func search(title: String, artist: String) async -> Data? {
        var components = URLComponents(string: "https://itunes.apple.com/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: "\(artist) \(TitleCleaner.clean(title))"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "1"),
        ]
        guard let url = components?.url,
              let data = await download(url),
              let response = try? JSONDecoder().decode(ITunesSearchResponse.self, from: data),
              let thumbnail = response.results.first?.artworkUrl100,
              let artworkURL = URL(string: thumbnail.replacing("100x100bb", with: "600x600bb"))
        else {
            return nil
        }
        return await download(artworkURL)
    }
}
