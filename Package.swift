// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "APIMonitor",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "APIMonitor",
            path: "Sources/APIMonitor",
            resources: [.process("Resources")]
        )
    ]
)
