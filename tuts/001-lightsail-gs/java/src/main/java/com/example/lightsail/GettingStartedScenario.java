// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.lightsail;

import software.amazon.awssdk.services.lightsail.LightsailClient;

public class GettingStartedScenario {
    public static void main(String[] args) {
        try (LightsailClient client = LightsailClient.builder().build()) {
            LightsailWrapper wrapper = new LightsailWrapper(client);
            System.out.println("Running Lightsail getting started scenario...");
            // TODO: setup, interact, teardown
            System.out.println("Scenario complete.");
        }
    }
}
