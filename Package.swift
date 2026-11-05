// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PreludeBridge",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "prelude-bridge", targets: ["PreludeBridge"])],
    targets: [
        .executableTarget(name: "PreludeBridge"),
        .testTarget(name: "PreludeBridgeTests", dependencies: ["PreludeBridge"]),
    ]
)
