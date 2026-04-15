<?php
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

namespace Example\Lightsail;

use Aws\Lightsail\LightsailClient;
use Aws\Exception\AwsException;

class LightsailWrapper
{
    private LightsailClient $client;

    public function __construct(LightsailClient $client)
    {
        $this->client = $client;
    }

    // TODO: Add wrapper methods matching CLI tutorial actions
}
