// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "UIChallenge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "UIChallenge", targets: ["UIChallenge"])
    ],
    targets: [
        .executableTarget(
            name: "UIChallenge"
        )
    ]
)
