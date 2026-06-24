// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.lightsail;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.lightsail.LightsailClient;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class LightsailWrapperTest {
    @Mock private LightsailClient mockClient;

    @Test
    void wrapperCreates() {
        LightsailWrapper wrapper = new LightsailWrapper(mockClient);
        assertNotNull(wrapper);
    }
}
