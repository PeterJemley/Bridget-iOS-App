// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BridgetCore",
    platforms: [
        .iOS("18.5")
    ],
    products: [
        .library(
            name: "BridgetCore",
            targets: ["BridgetCore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BridgetCore",
            dependencies: []),
        .testTarget(
            name: "BridgetCoreTests",
            dependencies: ["BridgetCore"]),
    ]
)
