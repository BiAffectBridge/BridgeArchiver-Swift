// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "BridgeArchiver",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .watchOS(.v4),
        .tvOS(.v14),
    ],
    products: [
        .library(
            name: "BridgeArchiver",
            targets: ["BridgeArchiver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.20"),
    ],
    targets: [
        // OpenSSL static library (iOS arm64 device + arm64/x86_64 simulator)
        .binaryTarget(
            name: "OpenSSL",
            path: "openssl/build/openssl.xcframework"
        ),
        // CMS encryption ObjC wrapper compiled directly by SPM (no CMSSupport.xcodeproj needed)
        .target(
            name: "CMSSupport",
            dependencies: [
                .target(name: "OpenSSL", condition: .when(platforms: [.iOS]))
            ],
            path: "Sources/CMSSupport",
            publicHeadersPath: "."
        ),
        // Main Swift library
        .target(
            name: "BridgeArchiver",
            dependencies: [
                "CMSSupport",
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "BridgeArchiverTests",
            dependencies: ["BridgeArchiver"],
            resources: [
                .process("resources")
            ]
        ),
    ]
)
