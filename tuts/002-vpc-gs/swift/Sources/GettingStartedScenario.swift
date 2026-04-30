// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import AWSEc2

@main
struct GettingStartedScenario {
    static func main() async throws {
        let client = try Ec2Client(region: "us-east-1")
        let wrapper = Ec2Wrapper(client: client)
        print("Running Ec2 getting started scenario...")
        // TODO: setup, interact, teardown
        let _ = wrapper
    }
}
