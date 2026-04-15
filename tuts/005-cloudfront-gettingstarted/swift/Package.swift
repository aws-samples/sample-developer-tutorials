// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "tutorial-cloudfront", dependencies: [.package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.36.0")], targets: [.executableTarget(name: "tutorial-cloudfront", dependencies: [.product(name: "AWSCloudFront", package: "aws-sdk-swift")])])
