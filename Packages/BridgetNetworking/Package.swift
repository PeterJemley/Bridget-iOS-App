// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BridgetNetworking",
    platforms: [
        .iOS("18.5")
    ],
    products: [
        .library(
            name: "BridgetNetworking",
            targets: ["BridgetNetworking"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore")
    ],
    targets: [
        .target(
            name: "BridgetNetworking",
            dependencies: ["BridgetCore"]),
        .testTarget(
            name: "BridgetNetworkingTests",
            dependencies: ["BridgetNetworking"]
        ),
    ]
)
