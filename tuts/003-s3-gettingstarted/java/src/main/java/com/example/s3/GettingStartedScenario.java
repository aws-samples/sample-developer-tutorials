// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.s3;

import software.amazon.awssdk.services.s3.S3Client;

public class GettingStartedScenario {
    public static void main(String[] args) {
        try (S3Client client = S3Client.builder().build()) {
            S3Wrapper wrapper = new S3Wrapper(client);
            System.out.println("Running S3 getting started scenario...");
            // TODO: setup, interact, teardown
            System.out.println("Scenario complete.");
        }
    }
}
