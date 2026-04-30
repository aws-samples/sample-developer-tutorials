<?php
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

namespace Example\S3;

use Aws\S3\S3Client;
use Aws\Exception\AwsException;

class S3Wrapper
{
    private S3Client $client;

    public function __construct(S3Client $client)
    {
        $this->client = $client;
    }

    // TODO: Add wrapper methods matching CLI tutorial actions
}
