// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

#include <aws/core/Aws.h>
#include <aws/lightsail/LightsailClient.h>
#include "lightsail_wrapper.h"
#include <iostream>

int main(int argc, char *argv[]) {
    Aws::SDKOptions options;
    Aws::InitAPI(options);
    {
        Aws::Lightsail::LightsailClient client;
        std::cout << "Running Lightsail getting started scenario..." << std::endl;
        // TODO: setup, interact, teardown
    }
    Aws::ShutdownAPI(options);
    return 0;
}
