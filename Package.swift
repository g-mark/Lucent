// swift-tools-version: 6.0

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
        )
    ]
)
