// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.ec2;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.ec2.Ec2Client;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class Ec2WrapperTest {
    @Mock private Ec2Client mockClient;

    @Test
    void wrapperCreates() {
        Ec2Wrapper wrapper = new Ec2Wrapper(mockClient);
        assertNotNull(wrapper);
    }
}
