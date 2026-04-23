// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { LightsailClient } from "@aws-sdk/client-lightsail";
import { randomUUID } from "crypto";

const main = async () => {
  const client = new LightsailClient({});
  const suffix = randomUUID().slice(0, 8);
  console.log("Running lightsail getting started scenario...");
  // TODO: implement setup, interact, teardown
  console.log("Scenario complete.");
};

main();
