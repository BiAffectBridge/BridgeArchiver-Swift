// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgeArchiver",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
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
                 url: "https://github.com/Sage-Bionetworks/CMSSupport.git",
                 .upToNextMajor(from: "1.2.0")),
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
                "CMSSupport",
                "ZIPFoundation",
            ]),
        .testTarget(
            name: "BridgeArchiverTests",
            dependencies: ["BridgeArchiver"],
            resources: [
                .process("Resources")
            ])
    ]
)
