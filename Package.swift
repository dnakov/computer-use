// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "computer-use-swift",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "computer-use", targets: ["ComputerUseCLI"]),
        .executable(name: "teach-overlay", targets: ["TeachOverlayApp"]),
        .library(name: "ComputerUseSwift", targets: ["ComputerUseSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .target(name: "ComputerUseSwift"),
        .executableTarget(
            name: "ComputerUseCLI",
            dependencies: [
                "ComputerUseSwift",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(name: "TeachOverlayApp"),
        .testTarget(
            name: "ComputerUseSwiftTests",
            dependencies: ["ComputerUseSwift"]
        ),
    ]
)
