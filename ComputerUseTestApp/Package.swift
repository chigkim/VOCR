// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ComputerUseTestApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ComputerUseTestApp", targets: ["ComputerUseTestApp"])
    ],
    targets: [
        .executableTarget(
            name: "ComputerUseTestApp"
        )
    ]
)
