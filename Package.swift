// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Fuzi",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7),
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
