// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cithare",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(name: "Cncurses", targets: ["Cncurses"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto", from: "2.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "Cncurses",
                path: "Sources/Cncurses",
                linkerSettings: [.linkedLibrary("ncurses")]
               ),
        .executableTarget(
            name: "cithare",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Crypto", package: "swift-crypto"),
                .target(name: "Cncurses")
            ]
        ),
        .testTarget(
            name: "cithareTests",
            dependencies: ["cithare"]),
    ]
)
