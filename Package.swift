// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "keychain",
    platforms: [
         .macOS(.v10_15)
      ],
    products: [
        .library(name: "Keychain", targets: ["Keychain"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.50.0"),
        .package(url: "https://github.com/nodes-vapor/submissions.git", from: "3.0.0-rc")
    ],
    targets: [
        .target(
            name: "Keychain",
            dependencies: [
                .product(name: "JWT", package: "jwt"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Submissions", package: "submissions"),
            ]
        ),
        .testTarget(name: "KeychainTests", dependencies: [
            .target(name:"Keychain"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
