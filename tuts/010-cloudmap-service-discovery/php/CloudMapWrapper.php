<?php
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

namespace Example\CloudMap;

use Aws\CloudMap\CloudMapClient;
use Aws\Exception\AwsException;

class CloudMapWrapper
{
    private CloudMapClient $client;

    public function __construct(CloudMapClient $client)
    {
        $this->client = $client;
    }

    // TODO: Add wrapper methods matching CLI tutorial actions
}
