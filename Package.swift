// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AICoachSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "AICoachSDK",
            targets: ["AICoachSDK"]
        ),
        .library(
            name: "AICoachUI",
            targets: ["AICoachUI"]
        )
    ],
    targets: [
        .target(
            name: "AICoachSDK",
            path: "Sources/AICoachSDK"
        ),
        .target(
            name: "AICoachUI",
            dependencies: ["AICoachSDK"],
            path: "Sources/AICoachUI",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "AICoachSDKTests",
            dependencies: ["AICoachSDK"],
            path: "Tests/AICoachSDKTests"
        )
    ]
)
