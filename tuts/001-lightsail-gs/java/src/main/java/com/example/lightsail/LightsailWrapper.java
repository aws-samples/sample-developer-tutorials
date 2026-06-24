// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.lightsail;

import software.amazon.awssdk.services.lightsail.LightsailClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class LightsailWrapper {
    private static final Logger logger = LoggerFactory.getLogger(LightsailWrapper.class);
    private final LightsailClient client;

    public LightsailWrapper(LightsailClient client) {
        this.client = client;
    }

    // TODO: Add wrapper methods matching CLI tutorial actions
}
