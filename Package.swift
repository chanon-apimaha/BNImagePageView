// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "BNImagePageView",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "BNImagePageView", targets: ["BNImagePageView"])
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "BNImagePageView",
            dependencies: ["Kingfisher"],
            path: "BNImagePageView/Classes"
        )
    ]
)
