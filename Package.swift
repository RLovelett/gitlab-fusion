// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gitlab-fusion",
    platforms: [
        .macOS(.v10_13),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(url: "https://github.com/mxcl/Path.swift.git", from: "1.0.0"),
        .package(name: "Environment", url: "https://github.com/wlisac/environment.git", from: "0.11.1"),
        .package(url: "https://github.com/jakeheis/Shout", from: "0.5.5"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "gitlab-fusion",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Environment", package: "Environment"),
                .product(name: "Path", package: "Path.swift"),
                .product(name: "Shout", package: "Shout"),
            ]
        ),
        .testTarget(
            name: "gitlab-fusionTests",
            dependencies: ["gitlab-fusion"]),
    ]
)
