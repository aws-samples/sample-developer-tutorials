// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.batch;

import software.amazon.awssdk.services.batch.BatchClient;

public class GettingStartedScenario {
    public static void main(String[] args) {
        try (BatchClient client = BatchClient.builder().build()) {
            BatchWrapper wrapper = new BatchWrapper(client);
            System.out.println("Running Batch getting started scenario...");
            // TODO: setup, interact, teardown
            System.out.println("Scenario complete.");
        }
    }
}
