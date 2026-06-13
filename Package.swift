// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Lucent",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Lucent",
            targets: ["Lucent"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/g-mark/Evident", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "603.0.0")
    ],
    targets: [
        .target(
            name: "LucentCore",
            dependencies: [
                .product(name: "Evident", package: "Evident")
            ],
            path: "Sources/Lucent"
        ),
        .target(
            name: "Lucent",
            dependencies: [
                "LucentCore",
                "LucentMacros"
            ],
            path: "Sources/LucentExports"
        ),
        .macro(
            name: "LucentMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "LucentTests",
            dependencies: [
                "LucentCore",
                .product(name: "Evident", package: "Evident")
            ]
        ),
        .testTarget(
            name: "LucentMacrosTests",
            dependencies: [
                "LucentMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        )
    ]
)


for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(contentsOf: [
        .defaultIsolation(nil),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances")
    ])
    target.swiftSettings = settings
}
