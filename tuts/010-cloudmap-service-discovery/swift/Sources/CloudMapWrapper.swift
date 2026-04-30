// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import AWSCloudMap
import Foundation

public class CloudMapWrapper {
    let client: CloudMapClient

    public init(client: CloudMapClient) {
        self.client = client
    }

    // TODO: Add async throws wrapper methods matching CLI tutorial actions
}
