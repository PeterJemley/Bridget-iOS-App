// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BridgetDashboard",
    platforms: [
        .iOS("18.5")
    ],
    products: [
        .library(
            name: "BridgetDashboard",
            targets: ["BridgetDashboard"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetSharedUI")
    ],
    targets: [
        .target(
            name: "BridgetDashboard",
            dependencies: ["BridgetCore", "BridgetSharedUI"]),
        .testTarget(
            name: "BridgetDashboardTests",
            dependencies: ["BridgetDashboard"]
        ),
    ]
)
