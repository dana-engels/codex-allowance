// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CodexAllowance",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "CodexAllowance", targets: ["CodexAllowance"])],
    targets: [
        .target(name: "AllowanceCore"),
        .target(name: "UsageService", dependencies: ["AllowanceCore"]),
        .executableTarget(name: "CodexAllowance", dependencies: ["AllowanceCore", "UsageService"]),
        .testTarget(name: "AllowanceCoreTests", dependencies: ["AllowanceCore", "UsageService"])
    ]
)
