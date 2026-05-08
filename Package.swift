// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BatteryRank",
    platforms: [.macOS(.v13)],
    targets: [
        .systemLibrary(name: "CLibProc"),
        .executableTarget(
            name: "BatteryRank",
            dependencies: ["CLibProc"],
            path: "Sources/BatteryRank"
        )
    ]
)
