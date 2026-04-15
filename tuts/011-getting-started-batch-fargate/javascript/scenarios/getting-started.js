// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { BatchClient } from "@aws-sdk/client-batch";
import { randomUUID } from "crypto";

const main = async () => {
  const client = new BatchClient({});
  const suffix = randomUUID().slice(0, 8);
  console.log("Running batch getting started scenario...");
  // TODO: implement setup, interact, teardown
  console.log("Scenario complete.");
};

main();
