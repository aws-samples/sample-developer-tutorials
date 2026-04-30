<?php
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

namespace Example\CloudFront;

use Aws\CloudFront\CloudFrontClient;
use Aws\Exception\AwsException;

class CloudFrontWrapper
{
    private CloudFrontClient $client;

    public function __construct(CloudFrontClient $client)
    {
        $this->client = $client;
    }

    // TODO: Add wrapper methods matching CLI tutorial actions
}
