// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Fuzi",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
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
            path: "Sources",
            linkerSettings: [
                .linkedLibrary("xml2")
            ]
        ),
        .testTarget(
            name: "FuziTests",
            dependencies: ["Fuzi"],
            path: "Tests"
        )
    ]
)
