// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BridgetSettings",
    platforms: [
        .iOS("18.5")
    ],
    products: [
        .library(
            name: "BridgetSettings",
            targets: ["BridgetSettings"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetSharedUI")
    ],
    targets: [
        .target(
            name: "BridgetSettings",
            dependencies: ["BridgetCore", "BridgetSharedUI"]),
        .testTarget(
            name: "BridgetSettingsTests",
            dependencies: ["BridgetSettings"]
        ),
    ]
)
