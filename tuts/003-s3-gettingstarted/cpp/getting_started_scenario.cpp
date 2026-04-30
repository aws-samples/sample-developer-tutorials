// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

#include <aws/core/Aws.h>
#include <aws/s3/S3Client.h>
#include "s3_wrapper.h"
#include <iostream>

int main(int argc, char *argv[]) {
    Aws::SDKOptions options;
    Aws::InitAPI(options);
    {
        Aws::S3::S3Client client;
        std::cout << "Running S3 getting started scenario..." << std::endl;
        // TODO: setup, interact, teardown
    }
    Aws::ShutdownAPI(options);
    return 0;
}
