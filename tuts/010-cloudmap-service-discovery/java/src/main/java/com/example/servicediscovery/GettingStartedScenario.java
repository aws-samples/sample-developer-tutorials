// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.servicediscovery;

import software.amazon.awssdk.services.servicediscovery.CloudMapClient;

public class GettingStartedScenario {
    public static void main(String[] args) {
        try (CloudMapClient client = CloudMapClient.builder().build()) {
            CloudMapWrapper wrapper = new CloudMapWrapper(client);
            System.out.println("Running CloudMap getting started scenario...");
            // TODO: setup, interact, teardown
            System.out.println("Scenario complete.");
        }
    }
}
