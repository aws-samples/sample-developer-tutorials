// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.cloudfront;

import software.amazon.awssdk.services.cloudfront.CloudFrontClient;

public class GettingStartedScenario {
    public static void main(String[] args) {
        try (CloudFrontClient client = CloudFrontClient.builder().build()) {
            CloudFrontWrapper wrapper = new CloudFrontWrapper(client);
            System.out.println("Running CloudFront getting started scenario...");
            // TODO: setup, interact, teardown
            System.out.println("Scenario complete.");
        }
    }
}
