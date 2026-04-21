// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.s3;

import software.amazon.awssdk.services.s3.S3Client;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class S3Wrapper {
    private static final Logger logger = LoggerFactory.getLogger(S3Wrapper.class);
    private final S3Client client;

    public S3Wrapper(S3Client client) {
        this.client = client;
    }

    // TODO: Add wrapper methods matching CLI tutorial actions
}
