// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "evaluator",
    platforms: [.iOS(.v15), .watchOS(.v8), .macOS(.v12)],
    products: [
        .library(name: "Evaluator", targets: ["Evaluator"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Evaluator",
            dependencies: []
        ),
        .testTarget(
            name: "EvaluatorTests",
            dependencies: ["Evaluator"]
        ),
    ]
)
