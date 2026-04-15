// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { CloudFrontClient } from "@aws-sdk/client-cloudfront";
import { randomUUID } from "crypto";

const main = async () => {
  const client = new CloudFrontClient({});
  const suffix = randomUUID().slice(0, 8);
  console.log("Running cloudfront getting started scenario...");
  // TODO: implement setup, interact, teardown
  console.log("Scenario complete.");
};

main();
