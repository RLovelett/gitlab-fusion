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
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .systemLibrary(
            name: "Clibssh",
            pkgConfig: "libssh",
            providers: [
                .brew(["libssh"])
            ]
        ),
        .target(
            name: "SecureShell",
            dependencies: ["Clibssh"]
        ),
        .target(
            name: "VMwareFusion",
            dependencies: [
                .product(name: "Path", package: "Path.swift"),
            ]
        ),
        .testTarget(
            name: "VMwareFusionTests",
            dependencies: [
                .target(name: "VMwareFusion"),
                .product(name: "Path", package: "Path.swift"),
            ]
        ),
        .target(
            name: "gitlab-fusion",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Environment", package: "Environment"),
                .product(name: "Path", package: "Path.swift"),
                .target(name: "SecureShell"),
                .target(name: "VMwareFusion"),
            ]
        ),
    ]
)
