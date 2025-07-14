// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BridgetBridgesList",
    platforms: [
        .iOS("18.5")
    ],
    products: [
        .library(
            name: "BridgetBridgesList",
            targets: ["BridgetBridgesList"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetSharedUI")
    ],
    targets: [
        .target(
            name: "BridgetBridgesList",
            dependencies: ["BridgetCore", "BridgetSharedUI"]),
        .testTarget(
            name: "BridgetBridgesListTests",
            dependencies: ["BridgetBridgesList"]
        ),
    ]
)
