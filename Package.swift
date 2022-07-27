// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WooshyWindowToTheForeground",
    platforms: [.macOS("11.5")],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(
            name: "WooshyWindowToTheForeground",
            targets: ["WooshyWindowToTheForeground"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/godbout/AlfredWorkflowScriptFilter",
            from: "1.0.0"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "WooshyWindowToTheForeground",
            dependencies: ["WooshyWindowToTheForegroundCore"]
        ),
        .target(
            name: "WooshyWindowToTheForegroundCore",
            dependencies: ["AlfredWorkflowScriptFilter"]),
        .testTarget(
            name: "WooshyWindowToTheForegroundCoreTests",
            dependencies: ["WooshyWindowToTheForegroundCore"],
            resources: [.process("Resources")]
        ),
    ]
)
