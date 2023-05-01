// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XcodeProjectPlugins",
    platforms: [
        .iOS(.v13),
        .watchOS(.v6),
        .macOS(.v10_15),
        .tvOS(.v13),
    ],
    products: [
        .plugin(
            name: "GenerateLocalisationEnumPlugin",
            targets: ["GenerateLocalisationEnumPlugin"]
        )
    ],
    targets: [
        .plugin(
            name: "GenerateLocalisationEnumPlugin",
            capability: .buildTool()
        )
    ]
)

