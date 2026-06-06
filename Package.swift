// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "HerdrMenuBar",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "HerdrCore",
            path: "Sources/HerdrCore"
        ),
        .executableTarget(
            name: "HerdrMenuBar",
            dependencies: ["HerdrCore"],
            path: "Sources/HerdrMenuBar"
        ),
        .testTarget(
            name: "HerdrCoreTests",
            dependencies: ["HerdrCore"],
            path: "Tests/HerdrCoreTests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
