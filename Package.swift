// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Trax",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Trax", targets: ["TraxApp"]),
        .library(name: "TraxDomain", targets: ["TraxDomain"]),
        .library(name: "TraxApplication", targets: ["TraxApplication"]),
        .library(name: "TraxFilePersistence", targets: ["TraxFilePersistence"])
    ],
    targets: [
        .target(name: "TraxDomain"),
        .target(
            name: "TraxApplication",
            dependencies: ["TraxDomain"]
        ),
        .target(
            name: "TraxFilePersistence",
            dependencies: ["TraxApplication", "TraxDomain"]
        ),
        .executableTarget(
            name: "TraxApp",
            dependencies: ["TraxApplication", "TraxDomain", "TraxFilePersistence"]
        ),
        .testTarget(
            name: "TraxDomainTests",
            dependencies: ["TraxDomain"]
        ),
        .testTarget(
            name: "TraxApplicationTests",
            dependencies: ["TraxApplication", "TraxDomain"]
        )
    ]
)
