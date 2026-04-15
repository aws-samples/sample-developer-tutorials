// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import AWSCloudFront

@main
struct GettingStartedScenario {
    static func main() async throws {
        let client = try CloudFrontClient(region: "us-east-1")
        let wrapper = CloudFrontWrapper(client: client)
        print("Running CloudFront getting started scenario...")
        // TODO: setup, interact, teardown
        let _ = wrapper
    }
}
