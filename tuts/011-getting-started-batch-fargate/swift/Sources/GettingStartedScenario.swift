// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import AWSBatch

@main
struct GettingStartedScenario {
    static func main() async throws {
        let client = try BatchClient(region: "us-east-1")
        let wrapper = BatchWrapper(client: client)
        print("Running Batch getting started scenario...")
        // TODO: setup, interact, teardown
        let _ = wrapper
    }
}
