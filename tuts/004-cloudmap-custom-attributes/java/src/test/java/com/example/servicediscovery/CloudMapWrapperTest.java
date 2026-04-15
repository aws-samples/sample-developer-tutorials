// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.servicediscovery;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.servicediscovery.CloudMapClient;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class CloudMapWrapperTest {
    @Mock private CloudMapClient mockClient;

    @Test
    void wrapperCreates() {
        CloudMapWrapper wrapper = new CloudMapWrapper(mockClient);
        assertNotNull(wrapper);
    }
}
