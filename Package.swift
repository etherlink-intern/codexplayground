// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftMarkItDown",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "SwiftMarkItDown", targets: ["SwiftMarkItDown"]),
        .executable(name: "swift-markitdown", targets: ["swift-markitdown"])
    ],
    targets: [
        .target(name: "SwiftMarkItDown"),
        .executableTarget(
            name: "swift-markitdown",
            dependencies: ["SwiftMarkItDown"]
        ),
        .testTarget(
            name: "SwiftMarkItDownTests",
            dependencies: ["SwiftMarkItDown"]
        )
    ]
)
