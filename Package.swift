// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IPAddrs",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(name: "IPAddrs", targets: ["IPAddrs"])
    ],
    targets: [
        .target(
            name: "IPAddrs",
            dependencies: [],
            path: "IPAddrs",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Core"),
            ]
        ),
    ]
)