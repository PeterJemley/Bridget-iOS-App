// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BridgetBridgeDetail",
    platforms: [
        .iOS("18.5")
    ],
    products: [
        .library(
            name: "BridgetBridgeDetail",
            targets: ["BridgetBridgeDetail"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetSharedUI")
    ],
    targets: [
        .target(
            name: "BridgetBridgeDetail",
            dependencies: ["BridgetCore", "BridgetSharedUI"]),
        .testTarget(
            name: "BridgetBridgeDetailTests",
            dependencies: ["BridgetBridgeDetail"]
        ),
    ]
)
