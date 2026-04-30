<?php
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

require 'vendor/autoload.php';

use Aws\CloudMap\CloudMapClient;

$client = new CloudMapClient(['region' => 'us-east-1']);
echo "Running CloudMap getting started scenario...\n";
// TODO: setup, interact, teardown
echo "Scenario complete.\n";
