// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "tutorial-ec2", dependencies: [.package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.36.0")], targets: [.executableTarget(name: "tutorial-ec2", dependencies: [.product(name: "AWSEc2", package: "aws-sdk-swift")])])
