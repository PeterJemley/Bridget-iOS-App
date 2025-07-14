// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BridgetHistory",
    platforms: [
        .iOS("18.5")
    ],
    products: [
        .library(
            name: "BridgetHistory",
            targets: ["BridgetHistory"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetSharedUI")
    ],
    targets: [
        .target(
            name: "BridgetHistory",
            dependencies: ["BridgetCore", "BridgetSharedUI"]),
        .testTarget(
            name: "BridgetHistoryTests",
            dependencies: ["BridgetHistory"]
        ),
    ]
)
