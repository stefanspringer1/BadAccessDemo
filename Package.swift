// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BadAccessDemo",
    dependencies: [
        .package(url: "https://github.com/stefanspringer1/SwiftXMLC", from: "0.0.225"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "BadAccessDemo",
            dependencies: ["SwiftXMLC"]),
    ]
)