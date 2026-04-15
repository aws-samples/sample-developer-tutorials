// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import AWSLightsail
import Foundation

public class LightsailWrapper {
    let client: LightsailClient

    public init(client: LightsailClient) {
        self.client = client
    }

    // TODO: Add async throws wrapper methods matching CLI tutorial actions
}
