<?php
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

namespace Example\Batch;

use Aws\Batch\BatchClient;
use Aws\Exception\AwsException;

class BatchWrapper
{
    private BatchClient $client;

    public function __construct(BatchClient $client)
    {
        $this->client = $client;
    }

    // TODO: Add wrapper methods matching CLI tutorial actions
}
