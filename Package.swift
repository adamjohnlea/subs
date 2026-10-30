// swift-tools-version: 6.4
import PackageDescription

let package = Package(
  name: "subs",
  platforms: [.macOS(.v26)],
  products: [
    .library(name: "SubtitleKit", targets: ["SubtitleKit"]),
    .library(name: "TranscriptionKit", targets: ["TranscriptionKit"]),
    .library(name: "CorrectionKit", targets: ["CorrectionKit"]),
    .executable(name: "subs", targets: ["subs"]),
  ],
  dependencies: [
    .package(url: "https://github.com/SwiftTUI/swift-tui.git", exact: "0.15.1"),
  ],
  targets: [
    .target(name: "SubtitleKit"),
    .target(name: "TranscriptionKit", dependencies: ["SubtitleKit"]),
    .target(name: "CorrectionKit", dependencies: ["SubtitleKit"]),
    .executableTarget(
      name: "subs",
      dependencies: [
        "SubtitleKit",
        "TranscriptionKit",
        "CorrectionKit",
        .product(name: "SwiftTUI", package: "swift-tui"),
      ]
    ),
    .testTarget(name: "SubtitleKitTests", dependencies: ["SubtitleKit"]),
    .testTarget(name: "TranscriptionKitTests", dependencies: ["TranscriptionKit", "SubtitleKit"]),
    .testTarget(name: "CorrectionKitTests", dependencies: ["CorrectionKit", "SubtitleKit"]),
    .testTarget(name: "subsTests", dependencies: ["subs", "SubtitleKit", "CorrectionKit"]),
  ],
  swiftLanguageModes: [.v6]
)
