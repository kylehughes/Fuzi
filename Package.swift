// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "Fuzi",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "Fuzi",
            targets: [
                "Fuzi"
            ]
        ),
    ],
    targets: [
        .target(
            name: "Fuzi",
            path: "Sources",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "FuziTests",
            dependencies: ["Fuzi"],
            path: "Tests",
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        )
    ]
)
