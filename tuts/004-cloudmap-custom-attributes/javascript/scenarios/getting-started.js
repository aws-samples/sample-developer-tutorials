// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { ServiceDiscoveryClient } from "@aws-sdk/client-servicediscovery";
import { randomUUID } from "crypto";

const main = async () => {
  const client = new ServiceDiscoveryClient({});
  const suffix = randomUUID().slice(0, 8);
  console.log("Running servicediscovery getting started scenario...");
  // TODO: implement setup, interact, teardown
  console.log("Scenario complete.");
};

main();
