// swift-tools-version: 6.1

import PackageDescription

let package = Package(
	name: "PDKPdfxr",
	platforms: [.macOS(.v14)],
	products: [
		.library(name: "PDKPdfxr", targets: ["PDKPdfxr"])
	],
	dependencies: [
		.package(url: "https://github.com/finnvoor/PlaydateKit.git", branch: "main"),
		.package(url: "https://github.com/strawdynamics/UTF8ViewExtensions.git", branch: "main"),
	],
	targets: [
		.target(
			name: "PDKPdfxr",
			dependencies: [
				.product(name: "PlaydateKit", package: "PlaydateKit"),
			],
			swiftSettings: [
				.enableExperimentalFeature("Embedded"),
				.unsafeFlags([
					"-whole-module-optimization",
					"-Xfrontend", "-disable-objc-interop",
					"-Xfrontend", "-disable-stack-protector",
					"-Xfrontend", "-function-sections",
					"-Xfrontend", "-gline-tables-only",
					"-Xcc", "-DTARGET_EXTENSION"
				]),
			],
		),
	],
	swiftLanguageModes: [.v6],
)
