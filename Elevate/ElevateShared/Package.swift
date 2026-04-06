// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ElevateShared",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ElevateShared", targets: ["ElevateShared"]),
    ],
    targets: [
        .target(name: "ElevateShared"),
    ]
)
