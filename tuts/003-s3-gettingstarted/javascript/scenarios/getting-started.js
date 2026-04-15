// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { S3Client } from "@aws-sdk/client-s3";
import { randomUUID } from "crypto";

const main = async () => {
  const client = new S3Client({});
  const suffix = randomUUID().slice(0, 8);
  console.log("Running s3 getting started scenario...");
  // TODO: implement setup, interact, teardown
  console.log("Scenario complete.");
};

main();
