// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "pushtester",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "pushtester", targets: ["pushtester"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "pushtester",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
