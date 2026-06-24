// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.servicediscovery;

import software.amazon.awssdk.services.servicediscovery.CloudMapClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class CloudMapWrapper {
    private static final Logger logger = LoggerFactory.getLogger(CloudMapWrapper.class);
    private final CloudMapClient client;

    public CloudMapWrapper(CloudMapClient client) {
        this.client = client;
    }

    // TODO: Add wrapper methods matching CLI tutorial actions
}
