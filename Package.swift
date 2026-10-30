// swift-tools-version: 6.4
import PackageDescription

let package = Package(
  name: "subs",
  platforms: [.macOS(.v26)],
  products: [
    .library(name: "SubtitleKit", targets: ["SubtitleKit"]),
    .library(name: "TranscriptionKit", targets: ["TranscriptionKit"]),
    .executable(name: "subs", targets: ["subs"]),
  ],
  dependencies: [
    .package(url: "https://github.com/SwiftTUI/swift-tui.git", exact: "0.15.1"),
  ],
  targets: [
    .target(name: "SubtitleKit"),
    .target(name: "TranscriptionKit", dependencies: ["SubtitleKit"]),
    .executableTarget(
      name: "subs",
      dependencies: [
        "SubtitleKit",
        "TranscriptionKit",
        .product(name: "SwiftTUI", package: "swift-tui"),
      ]
    ),
    .testTarget(name: "SubtitleKitTests", dependencies: ["SubtitleKit"]),
    .testTarget(name: "TranscriptionKitTests", dependencies: ["TranscriptionKit", "SubtitleKit"]),
    .testTarget(name: "subsTests", dependencies: ["subs", "SubtitleKit"]),
  ],
  swiftLanguageModes: [.v6]
)
