// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import AWSS3
import Foundation

public class S3Wrapper {
    let client: S3Client

    public init(client: S3Client) {
        self.client = client
    }

    // TODO: Add async throws wrapper methods matching CLI tutorial actions
}
