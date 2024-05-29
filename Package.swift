// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgeArchiver",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .watchOS(.v4),
        .tvOS(.v11),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BridgeArchiver",
            targets: ["BridgeArchiver"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "CMSSupport",
                 url: "https://github.com/BiAffectBridge/CMSSupport.git",
                 .upToNextMajor(from: "1.2.3")),
        .package(name: "ZIPFoundation",
                 url: "https://github.com/weichsel/ZIPFoundation.git",
                 .upToNextMajor(from: "0.9.0"))

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BridgeArchiver",
            dependencies: [
                // syoung 04/05/2022 https://bugs.swift.org/browse/SR-15196 Cannot build a binary conditionally.
                // syoung 02/21/2022 Update - Xcode 14.3 beta fixes this issue.
                .product(name: "CMSSupport", package: "CMSSupport"),
                "ZIPFoundation",
            ]),
        .testTarget(
            name: "BridgeArchiverTests",
            dependencies: ["BridgeArchiver"],
            resources: [
                .process("resources")
            ])
    ]
)
