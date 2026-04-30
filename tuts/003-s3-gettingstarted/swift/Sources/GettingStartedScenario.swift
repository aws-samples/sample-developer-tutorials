// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import AWSS3

@main
struct GettingStartedScenario {
    static func main() async throws {
        let client = try S3Client(region: "us-east-1")
        let wrapper = S3Wrapper(client: client)
        print("Running S3 getting started scenario...")
        // TODO: setup, interact, teardown
        let _ = wrapper
    }
}
