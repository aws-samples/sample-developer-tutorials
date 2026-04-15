<?php
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

require 'vendor/autoload.php';

use Aws\Ec2\Ec2Client;

$client = new Ec2Client(['region' => 'us-east-1']);
echo "Running Ec2 getting started scenario...\n";
// TODO: setup, interact, teardown
echo "Scenario complete.\n";
