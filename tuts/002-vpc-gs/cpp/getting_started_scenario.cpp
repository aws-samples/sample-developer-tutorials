// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

#include <aws/core/Aws.h>
#include <aws/ec2/Ec2Client.h>
#include "ec2_wrapper.h"
#include <iostream>

int main(int argc, char *argv[]) {
    Aws::SDKOptions options;
    Aws::InitAPI(options);
    {
        Aws::Ec2::Ec2Client client;
        std::cout << "Running Ec2 getting started scenario..." << std::endl;
        // TODO: setup, interact, teardown
    }
    Aws::ShutdownAPI(options);
    return 0;
}
