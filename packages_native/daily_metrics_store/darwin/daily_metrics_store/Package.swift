// swift-tools-version: 5.9

import PackageDescription

// SwiftData needs iOS 17 / macOS 14, so the app's deployment targets are
// raised to match (app/ios, app/macos project.pbxproj).
let package = Package(
    name: "daily_metrics_store",
    platforms: [
        .iOS("17.0"),
        .macOS("14.0"),
    ],
    products: [
        .library(name: "daily-metrics-store", targets: ["daily_metrics_store"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "daily_metrics_store",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
