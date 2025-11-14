// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AuthLocker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "AuthLockerCore", targets: ["AuthLockerCore"]),
        .library(name: "AuthLockerUIKit", targets: ["AuthLockerUIKit"]),
        .library(name: "AuthLockerSwiftUIAdapter", targets: ["AuthLockerSwiftUIAdapter"]) 
        , .executable(name: "AuthLockerBench", targets: ["AuthLockerBench"]) 
    ],
    targets: [
        .target(
            name: "AuthLockerCore",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "AuthLockerUIKit",
            dependencies: ["AuthLockerCore"]
        ),
        .target(
            name: "AuthLockerSwiftUIAdapter",
            dependencies: ["AuthLockerCore", "AuthLockerUIKit"]
        ),
        .testTarget(
            name: "AuthLockerCoreTests",
            dependencies: ["AuthLockerCore"]
        ),
        .executableTarget(
            name: "AuthLockerBench",
            dependencies: ["AuthLockerCore"]
        )
    ]
)
