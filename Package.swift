// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Dollup",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "dollup", targets: ["DollupTool"]),
        .library(name: "Dollup", targets: ["Dollup"]),
        .library(name: "DollupCheck", targets: ["DollupCheck"]),
        .library(name: "DollupConfig", targets: ["DollupConfig"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rarestype/h", from: "1.0.1"),
        .package(url: "https://github.com/rarestype/swift-io", from: "3.0.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "603.0.0" ..< "604.0.0")
    ],
    targets: [
        .executableTarget(
            name: "DollupTool",
            dependencies: [
                .target(name: "DollupConfig"),
            ]
        ),

        .target(
            name: "DollupConfig",
            dependencies: [
                .target(name: "Dollup"),
                .target(name: "DollupCheck"),
                .product(name: "SHA2", package: "h"),
                .product(name: "System_ArgumentParser", package: "swift-io"),
                .product(name: "SystemIO", package: "swift-io"),
            ]
        ),
        .target(
            name: "Dollup",
            dependencies: [
                .target(name: "DollupCheck"),
                .target(name: "WhitespaceFormatter"),
            ]
        ),
        .target(
            name: "DollupCheck",
            dependencies: [
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SystemIO", package: "swift-io"),
            ]
        ),
        .target(
            name: "WhitespaceFormatter",
            dependencies: [
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "DollupCheckTests",
            dependencies: [
                .target(name: "DollupCheck"),
            ]
        ),
        .testTarget(
            name: "WhitespaceFormatterTests",
            dependencies: [
                .target(name: "WhitespaceFormatter"),
            ],
            path: "Tests/WhitespaceFormatter"
        ),
    ]
)
for target: Target in package.targets {
    switch target.type {
    case .plugin: continue
    case .binary: continue
    default: break
    }
    {
        $0 = ($0 ?? []) + [
            .enableUpcomingFeature("ExistentialAny")
        ]
    }(&target.swiftSettings)
}
