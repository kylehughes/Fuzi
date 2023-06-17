// swift-tools-version:5.7

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
        .target(name: "Fuzi",
            path: "Sources"
        ),
        .testTarget(
            name: "FuziTests",
            dependencies: ["Fuzi"],
            path: "Tests"
        )
    ]
)
