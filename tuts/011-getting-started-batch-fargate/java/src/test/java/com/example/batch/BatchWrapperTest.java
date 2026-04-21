// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.batch;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.batch.BatchClient;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class BatchWrapperTest {
    @Mock private BatchClient mockClient;

    @Test
    void wrapperCreates() {
        BatchWrapper wrapper = new BatchWrapper(mockClient);
        assertNotNull(wrapper);
    }
}
