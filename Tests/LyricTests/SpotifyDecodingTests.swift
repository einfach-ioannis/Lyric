import Foundation
import Testing
@testable import Lyric

struct SpotifyDecodingTests {
    private let playlistsJSON = """
    {
      "href": "https://api.spotify.com/v1/me/playlists?offset=0&limit=50",
      "limit": 50,
      "next": null,
      "offset": 0,
      "total": 3,
      "items": [
        {
          "collaborative": false,
          "id": "37i9dQZF1DXcBWIGoYBM5M",
          "uri": "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M",
          "name": "Today's Top Hits",
          "images": [{"url": "https://i.scdn.co/image/large", "height": 640, "width": 640}, {"url": "https://i.scdn.co/image/small", "height": 60, "width": 60}],
          "tracks": {"href": "https://api.spotify.com/v1/playlists/37i9dQZF1DXcBWIGoYBM5M/tracks", "total": 50}
        },
        null,
        {
          "id": "abc",
          "uri": "spotify:playlist:abc",
          "name": "Empty",
          "images": null,
          "tracks": {"href": "https://api.spotify.com/v1/playlists/abc/tracks", "total": 1}
        }
      ]
    }
    """

    private let queueJSON = """
    {
      "currently_playing": {"name": "Now", "uri": "spotify:track:now", "duration_ms": 1000, "artists": [{"name": "X"}], "album": {"images": []}},
      "queue": [
        {
          "name": "Blinding Lights",
          "uri": "spotify:track:0VjIjW4GlUZAMYd2vXMi3b",
          "duration_ms": 200040,
          "artists": [{"name": "The Weeknd"}],
          "album": {"name": "After Hours", "images": [{"url": "https://i.scdn.co/image/album"}]}
        },
        {
          "name": "Blinding Lights",
          "uri": "spotify:track:0VjIjW4GlUZAMYd2vXMi3b",
          "duration_ms": 200040,
          "artists": [{"name": "The Weeknd"}],
          "album": {"images": []}
        },
        {
          "name": "Episode 12",
          "uri": "spotify:episode:4rOoJ6Egrf8K2IrywzwOMk",
          "duration_ms": 3600000,
          "images": [{"url": "https://i.scdn.co/image/episode"}],
          "show": {"name": "A Podcast", "images": []}
        }
      ]
    }
    """

    @Test func mapsPlaylistsAfterLikedSongs() throws {
        let page = try SpotifyEndpoints.decoder().decode(SpotifyPlaylistPage.self, from: Data(playlistsJSON.utf8))
        let summaries = page.summaries(userID: "listener", likedSongCount: 412)

        #expect(summaries.count == 3)
        #expect(summaries[0].id == "spotify:user:listener:collection")
        #expect(summaries[0].name == "Liked Songs")
        #expect(summaries[0].detail == "412 songs")
        #expect(summaries[1].id == "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M")
        #expect(summaries[1].name == "Today's Top Hits")
        #expect(summaries[1].detail == "50 songs")
        #expect(summaries[1].artworkURL == URL(string: "https://i.scdn.co/image/large"))
        #expect(summaries[2].detail == "1 song")
        #expect(summaries[2].artworkURL == nil)
        #expect(summaries.allSatisfy { $0.source == .spotify })
        #expect(summaries[0].isLikedSongs)
        #expect(!summaries[1].isLikedSongs)
    }

    @Test func hidesZeroSongCount() throws {
        let json = #"{"items": [{"uri": "spotify:playlist:x", "name": "Followed", "images": [], "items": {"total": 0}}]}"#
        let page = try SpotifyEndpoints.decoder().decode(SpotifyPlaylistPage.self, from: Data(json.utf8))
        #expect(page.summaries(userID: "listener", likedSongCount: nil)[1].detail.isEmpty)
    }

    @Test func mapsQueueTracksAndEpisodes() throws {
        let response = try SpotifyEndpoints.decoder().decode(SpotifyQueueResponse.self, from: Data(queueJSON.utf8))
        let items = response.items()

        #expect(items.count == 3)
        #expect(items[0].title == "Blinding Lights")
        #expect(items[0].artist == "The Weeknd")
        #expect(items[0].duration == 200.04)
        #expect(items[0].artworkURL == URL(string: "https://i.scdn.co/image/album"))
        #expect(items[0].id != items[1].id)
        #expect(items[2].artist == "A Podcast")
        #expect(items[2].artworkURL == URL(string: "https://i.scdn.co/image/episode"))
    }

    @Test func emptyQueueDecodes() throws {
        let response = try SpotifyEndpoints.decoder().decode(SpotifyQueueResponse.self, from: Data(#"{"currently_playing": null, "queue": []}"#.utf8))
        #expect(response.items().isEmpty)
    }
}
