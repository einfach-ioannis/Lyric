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
        async let exactRecord = exactMatch(for: track)
        async let searchResults = search(title: TitleCleaner.clean(track.title), artist: track.artist)
        let exact = await exactRecord
        let candidates = await searchResults.filter { record in
            LyricsMatcher.accepts(
                title: record.trackName,
                artist: record.artistName,
                durationDistance: durationDistance(record, track),
                for: track
            )
        }

        if exact?.instrumental == true {
            return .instrumental
        }

        // Synced uploads, closest in length first (the exact match is closest by definition).
        // The closest one is used, with any single badly timed line fixed by the others.
        let synced = ([exact].compactMap { $0 } + candidates.sorted { durationDistance($0, track) < durationDistance($1, track) })
            .compactMap { record -> [LyricLine]? in
                guard let text = record.syncedLyrics, !text.isEmpty else { return nil }
                let lines = LRCParser.parse(text)
                return lines.isEmpty ? nil : lines
            }
        if let base = synced.first {
            let corrected = LyricsConsensus.corrected(base, using: Array(synced.dropFirst()))
            // A moved line may now belong elsewhere in the order.
            let lines = LyricBreaks.inserting(into: corrected.sorted { $0.time < $1.time })
            return .loaded(Lyrics(lines: lines, isSynced: true))
        }

        let plain = [exact].compactMap { $0 } + candidates.sorted { durationDistance($0, track) < durationDistance($1, track) }
        if let record = plain.first(where: { $0.plainLyrics?.isEmpty == false || $0.instrumental == true }),
           let state = state(from: record) {
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
