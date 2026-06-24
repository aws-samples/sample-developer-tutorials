// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.cloudfront;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.cloudfront.CloudFrontClient;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class CloudFrontWrapperTest {
    @Mock private CloudFrontClient mockClient;

    @Test
    void wrapperCreates() {
        CloudFrontWrapper wrapper = new CloudFrontWrapper(mockClient);
        assertNotNull(wrapper);
    }
}
