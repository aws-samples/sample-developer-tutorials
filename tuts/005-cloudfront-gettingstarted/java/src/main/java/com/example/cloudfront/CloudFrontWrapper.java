// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.cloudfront;

import software.amazon.awssdk.services.cloudfront.CloudFrontClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class CloudFrontWrapper {
    private static final Logger logger = LoggerFactory.getLogger(CloudFrontWrapper.class);
    private final CloudFrontClient client;

    public CloudFrontWrapper(CloudFrontClient client) {
        this.client = client;
    }

    // TODO: Add wrapper methods matching CLI tutorial actions
}
