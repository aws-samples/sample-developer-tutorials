// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "tutorial-lightsail", dependencies: [.package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.36.0")], targets: [.executableTarget(name: "tutorial-lightsail", dependencies: [.product(name: "AWSLightsail", package: "aws-sdk-swift")])])
