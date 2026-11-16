import Foundation

/// Fetches lyrics from LRCLIB, a free and open lyrics database, and caches them per track.
actor LyricsService {
    private var cache: [String: LyricsState] = [:]
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["User-Agent": "Lyric/1.0 (macOS)"]
        configuration.timeoutIntervalForRequest = 10
        session = URLSession(configuration: configuration)
    }

    func lyrics(for track: Track) async -> LyricsState {
        if let cached = cache[track.id] {
            return cached
        }

        let state = await fetch(track)
        if state != .loading {
            cache[track.id] = state
        }
        return state
    }

    private func fetch(_ track: Track) async -> LyricsState {
        if let exact = await exactMatch(for: track), let state = state(from: exact) {
            return state
        }

        let candidates = await search(title: TitleCleaner.clean(track.title), artist: track.artist)
        let ranked = candidates.sorted { lhs, rhs in
            durationDistance(lhs, track) < durationDistance(rhs, track)
        }
        let best = ranked.first { $0.syncedLyrics?.isEmpty == false } ?? ranked.first { $0.plainLyrics?.isEmpty == false }

        if let best,
           LyricsMatcher.accepts(
               title: best.trackName,
               artist: best.artistName,
               durationDistance: durationDistance(best, track),
               for: track
           ),
           let state = state(from: best) {
            return state
        }
        return .unavailable
    }

    private func exactMatch(for track: Track) async -> LRCLibRecord? {
        var components = URLComponents(string: "https://lrclib.net/api/get")
        components?.queryItems = [
            URLQueryItem(name: "track_name", value: track.title),
            URLQueryItem(name: "artist_name", value: track.artist),
            URLQueryItem(name: "album_name", value: track.album),
            URLQueryItem(name: "duration", value: String(Int(track.duration.rounded()))),
        ]
        return await decode(LRCLibRecord.self, from: components?.url)
    }

    private func search(title: String, artist: String) async -> [LRCLibRecord] {
        var components = URLComponents(string: "https://lrclib.net/api/search")
        components?.queryItems = [
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "artist_name", value: artist),
        ]
        return await decode([LRCLibRecord].self, from: components?.url) ?? []
    }

    private func decode<Value: Decodable>(_ type: Value.Type, from url: URL?) async -> Value? {
        guard let url else { return nil }
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return nil
        }
    }

    private func state(from record: LRCLibRecord) -> LyricsState? {
        if record.instrumental == true {
            return .instrumental
        }
        if let synced = record.syncedLyrics, !synced.isEmpty {
            let lines = LRCParser.parse(synced)
            if !lines.isEmpty {
                return .loaded(Lyrics(lines: lines, isSynced: true))
            }
        }
        if let plain = record.plainLyrics, !plain.isEmpty {
            return .loaded(Lyrics(lines: LRCParser.plainLines(plain), isSynced: false))
        }
        return nil
    }

    private func durationDistance(_ record: LRCLibRecord, _ track: Track) -> Double {
        guard let duration = record.duration, track.duration > 0 else { return 0 }
        return abs(duration - track.duration)
    }
}
