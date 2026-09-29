// swift-tools-version: 6.4
import PackageDescription

let package = Package(
  name: "subs",
  platforms: [.macOS(.v26)],
  products: [
    .library(name: "SubtitleKit", targets: ["SubtitleKit"]),
    .executable(name: "subs", targets: ["subs"]),
  ],
  dependencies: [
    .package(url: "https://github.com/SwiftTUI/swift-tui.git", exact: "0.15.1"),
  ],
  targets: [
    .target(name: "SubtitleKit"),
    .executableTarget(
      name: "subs",
      dependencies: [
        "SubtitleKit",
        .product(name: "SwiftTUI", package: "swift-tui"),
      ]
    ),
    .testTarget(name: "SubtitleKitTests", dependencies: ["SubtitleKit"]),
  ],
  swiftLanguageModes: [.v6]
)
