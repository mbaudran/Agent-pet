// swift-tools-version:6.0
// Build without Xcode: SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk swift build
// (the macOS 27 SDK lacks the SwiftUI and Swift Testing macro plugins).
import PackageDescription

let settings: [SwiftSetting] = [.swiftLanguageMode(.v5)]

let package = Package(
    name: "Keloqz",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "KeloqzCore", swiftSettings: settings),
        .executableTarget(
            name: "Keloqz",
            dependencies: ["KeloqzCore"],
            resources: [.copy("Resources/sprites")],
            swiftSettings: settings
        ),
        .testTarget(
            name: "KeloqzCoreTests",
            dependencies: ["KeloqzCore"],
            resources: [.copy("Fixtures")],
            swiftSettings: settings
        ),
    ]
)
