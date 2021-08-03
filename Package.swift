// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClippingBezier",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ClippingBezier",
            targets: ["ClippingBezier"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/adamwulf/PerformanceBezier.git", from: "1.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ClippingBezier",
            dependencies: [ "PerformanceBezier" ],
            path: "ClippingBezier",
            exclude: ["Info.plist",
                      "ClippingBezier-Info.plist",
                      "BezierUtilsLicense",
                      "bezierclip.hxx",
                      "gauss.hxx",],
            sources: ["."],
            publicHeadersPath: "PublicHeaders"),
        .testTarget(
            name: "ClippingBezierTests",
            dependencies: ["ClippingBezier"],
            path: "ClippingBezierTests",
            exclude: ["Info.plist"]),
    ],
    cLanguageStandard: .gnu99,
    cxxLanguageStandard: .gnucxx11
)
