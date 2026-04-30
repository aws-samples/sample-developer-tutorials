// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import AWSBatch
import Foundation

public class BatchWrapper {
    let client: BatchClient

    public init(client: BatchClient) {
        self.client = client
    }

    // TODO: Add async throws wrapper methods matching CLI tutorial actions
}
