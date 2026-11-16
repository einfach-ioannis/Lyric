// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Lyric",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "Lyric",
            path: "Sources/Lyric",
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
        .testTarget(
            name: "LyricTests",
            dependencies: ["Lyric"],
            path: "Tests/LyricTests"
        ),
    ]
)
