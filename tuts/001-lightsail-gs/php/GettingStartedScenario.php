<?php
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

require 'vendor/autoload.php';

use Aws\Lightsail\LightsailClient;

$client = new LightsailClient(['region' => 'us-east-1']);
echo "Running Lightsail getting started scenario...\n";
// TODO: setup, interact, teardown
echo "Scenario complete.\n";
