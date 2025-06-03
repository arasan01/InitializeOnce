// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "InitializeOnce",
  platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10)],
  products: [
    .library(
      name: "InitializeOnce",
      targets: ["InitializeOnce"]
    ),
    .library(name: "Example", targets: ["Example"]),
  ],
  targets: [
    .target(
      name: "InitializeOnce"
    ),
    .target(
      name: "Example",
      dependencies: ["InitializeOnce"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
