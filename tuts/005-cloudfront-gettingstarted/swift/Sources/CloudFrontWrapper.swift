// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import AWSCloudFront
import Foundation

public class CloudFrontWrapper {
    let client: CloudFrontClient

    public init(client: CloudFrontClient) {
        self.client = client
    }

    // TODO: Add async throws wrapper methods matching CLI tutorial actions
}
