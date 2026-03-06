// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MealFlowDomain",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MealFlowDomain",
            targets: ["MealFlowDomain"]
        )
    ],
    targets: [
        .target(
            name: "MealFlowDomain",
            path: "MealFlowDomain/Sources"
        ),
        .testTarget(
            name: "MealFlowDomainTests",
            dependencies: ["MealFlowDomain"],
            path: "MealFlowDomain/Tests"
        )
    ]
)
