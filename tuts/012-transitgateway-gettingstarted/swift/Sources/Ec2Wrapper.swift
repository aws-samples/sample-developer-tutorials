// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import AWSEc2
import Foundation

public class Ec2Wrapper {
    let client: Ec2Client

    public init(client: Ec2Client) {
        self.client = client
    }

    // TODO: Add async throws wrapper methods matching CLI tutorial actions
}
