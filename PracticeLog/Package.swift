// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "PracticeLog",
  products: [
    .library(name: "PracticeLog", targets: ["PracticeLog"]),
  ],
  targets: [
    .target(name: "PracticeLog"),
    .testTarget(
      name: "PracticeLogTests",
      dependencies: ["PracticeLog"]
    ),
  ]
)
