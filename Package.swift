// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "HerdrMenuBar",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "HerdrCore",
            path: "Sources/HerdrCore",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "HerdrMenuBar",
            dependencies: ["HerdrCore"],
            path: "Sources/HerdrMenuBar",
            resources: [
                .copy("Resources")
            ]
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
