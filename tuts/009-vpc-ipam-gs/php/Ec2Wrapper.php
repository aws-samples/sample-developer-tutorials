<?php
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

namespace Example\Ec2;

use Aws\Ec2\Ec2Client;
use Aws\Exception\AwsException;

class Ec2Wrapper
{
    private Ec2Client $client;

    public function __construct(Ec2Client $client)
    {
        $this->client = $client;
    }

    // TODO: Add wrapper methods matching CLI tutorial actions
}
