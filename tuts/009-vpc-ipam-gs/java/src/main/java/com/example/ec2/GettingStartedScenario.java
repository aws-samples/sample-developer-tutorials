// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.ec2;

import software.amazon.awssdk.services.ec2.Ec2Client;

public class GettingStartedScenario {
    public static void main(String[] args) {
        try (Ec2Client client = Ec2Client.builder().build()) {
            Ec2Wrapper wrapper = new Ec2Wrapper(client);
            System.out.println("Running Ec2 getting started scenario...");
            // TODO: setup, interact, teardown
            System.out.println("Scenario complete.");
        }
    }
}
