// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.ec2;

import software.amazon.awssdk.services.ec2.Ec2Client;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Ec2Wrapper {
    private static final Logger logger = LoggerFactory.getLogger(Ec2Wrapper.class);
    private final Ec2Client client;

    public Ec2Wrapper(Ec2Client client) {
        this.client = client;
    }

    // TODO: Add wrapper methods matching CLI tutorial actions
}
