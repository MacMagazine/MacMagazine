// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Videos",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Videos", targets: ["Videos"])
    ],
    dependencies: [
        .package(name: "CommonLibrary", path: "../CommonLibrary"),
        .package(url: "https://bitbucket.org/kasros/modules.git", branch: "master")
    ],
    targets: [
        .target(name: "Videos",
                dependencies: ["CommonLibrary",
                               .product(name: "YouTubeLibrary", package: "modules"),
                               .product(name: "CoreLibrary", package: "modules"),
                               .product(name: "UIComponentsLibrarySpecial", package: "modules")])
    ]
)
