// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pen",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Pen", targets: ["Pen"]),
    ],
    targets: [
        .executableTarget(
            name: "Pen",
            path: "Sources/Pen"
        ),
    ]
)
