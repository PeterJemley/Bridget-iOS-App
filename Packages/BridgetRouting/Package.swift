// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BridgetRouting",
    platforms: [
        .iOS("18.5")
    ],
    products: [
        .library(
            name: "BridgetRouting",
            targets: ["BridgetRouting"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetSharedUI")
    ],
    targets: [
        .target(
            name: "BridgetRouting",
            dependencies: ["BridgetCore", "BridgetSharedUI"]),
        .testTarget(
            name: "BridgetRoutingTests",
            dependencies: ["BridgetRouting"]
        ),
    ]
)
