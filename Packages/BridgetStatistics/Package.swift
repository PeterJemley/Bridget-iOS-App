// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BridgetStatistics",
    platforms: [
        .iOS("18.5")
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
