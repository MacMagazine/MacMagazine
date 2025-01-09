// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CommonLibrary",
	platforms: [.iOS(.v17)],
    products: [
        .library(name: "CommonLibrary", targets: ["CommonLibrary"]),
    ],
	dependencies: [
		.package(url: "https://bitbucket.org/kasros/modules.git", branch: "master"),
	],
    targets: [
		.target(name: "CommonLibrary",
				dependencies: [.product(name: "CoreLibrary", package: "modules"),
							   .product(name: "UIComponentsLibrary", package: "modules")],
				resources: [.process("Resources")])
    ]
)
