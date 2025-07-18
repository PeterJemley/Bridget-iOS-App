// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BridgetSharedUI",
    platforms: [
        .iOS("17.0"),
        .macOS("14.0")
    ],
    products: [
        .library(
            name: "BridgetSharedUI",
            targets: ["BridgetSharedUI"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore")
    ],
    targets: [
        .target(
            name: "BridgetSharedUI",
            dependencies: ["BridgetCore"]),
        .testTarget(
            name: "BridgetSharedUITests",
            dependencies: ["BridgetSharedUI"]
        ),
    ]
)
