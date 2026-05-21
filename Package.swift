// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StorageCleanerMac",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "StorageCleanerMac",
            path: "Sources/StorageCleanerMac"
        )
    ]
)
