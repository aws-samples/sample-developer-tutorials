// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "tutorial-s3", dependencies: [.package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.36.0")], targets: [.executableTarget(name: "tutorial-s3", dependencies: [.product(name: "AWSS3", package: "aws-sdk-swift")])])
