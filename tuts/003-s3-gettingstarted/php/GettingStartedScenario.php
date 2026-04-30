<?php
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

require 'vendor/autoload.php';

use Aws\S3\S3Client;

$client = new S3Client(['region' => 'us-east-1']);
echo "Running S3 getting started scenario...\n";
// TODO: setup, interact, teardown
echo "Scenario complete.\n";
