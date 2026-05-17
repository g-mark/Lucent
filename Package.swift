// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Lucent",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Lucent",
            targets: ["Lucent"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/g-mark/Evident", branch: "main")
    ],
    targets: [
        .target(
            name: "Lucent",
            dependencies: [
                .product(name: "Evident", package: "Evident")
            ]
        ),
        .testTarget(
            name: "LucentTests",
            dependencies: [
                "Lucent",
                .product(name: "Evident", package: "Evident")
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
