// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import AWSLightsail

@main
struct GettingStartedScenario {
    static func main() async throws {
        let client = try LightsailClient(region: "us-east-1")
        let wrapper = LightsailWrapper(client: client)
        print("Running Lightsail getting started scenario...")
        // TODO: setup, interact, teardown
        let _ = wrapper
    }
}
