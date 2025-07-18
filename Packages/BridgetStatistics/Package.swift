// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BridgetStatistics",
    platforms: [
        .iOS("17.0"),
        .macOS("14.0")
    ],
    products: [
        .library(
            name: "BridgetStatistics",
            targets: ["BridgetStatistics"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetSharedUI")
    ],
    targets: [
        .target(
            name: "BridgetStatistics",
            dependencies: ["BridgetCore", "BridgetSharedUI"]),
        .testTarget(
            name: "BridgetStatisticsTests",
            dependencies: ["BridgetStatistics"]
        ),
    ]
)
