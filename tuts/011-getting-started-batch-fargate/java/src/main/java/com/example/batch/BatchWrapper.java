// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.batch;

import software.amazon.awssdk.services.batch.BatchClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BatchWrapper {
    private static final Logger logger = LoggerFactory.getLogger(BatchWrapper.class);
    private final BatchClient client;

    public BatchWrapper(BatchClient client) {
        this.client = client;
    }

    // TODO: Add wrapper methods matching CLI tutorial actions
}
