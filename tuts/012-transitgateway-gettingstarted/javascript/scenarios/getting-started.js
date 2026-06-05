// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { EC2Client } from "@aws-sdk/client-ec2";
import { randomUUID } from "crypto";

const main = async () => {
  const client = new EC2Client({});
  const suffix = randomUUID().slice(0, 8);
  console.log("Running ec2 getting started scenario...");
  // TODO: implement setup, interact, teardown
  console.log("Scenario complete.");
};

main();
