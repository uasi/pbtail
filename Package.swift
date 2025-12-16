// swift-tools-version: 6.2
// SPDX-License-Identifier: 0BSD

import PackageDescription

let package = Package(
    name: "pbtail",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.2")
    ],
    targets: [
        .executableTarget(
            name: "pbtail",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "PbtailTests", dependencies: [.target(name: "pbtail")]
        ),
    ]
)
