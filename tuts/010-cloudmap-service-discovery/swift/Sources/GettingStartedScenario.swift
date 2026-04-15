// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import AWSCloudMap

@main
struct GettingStartedScenario {
    static func main() async throws {
        let client = try CloudMapClient(region: "us-east-1")
        let wrapper = CloudMapWrapper(client: client)
        print("Running CloudMap getting started scenario...")
        // TODO: setup, interact, teardown
        let _ = wrapper
    }
}
