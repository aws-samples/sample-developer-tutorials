// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { describe, it, expect, beforeEach } from "vitest";
import { mockClient } from "aws-sdk-client-mock";
import { EC2Client } from "@aws-sdk/client-ec2";

const mock = mockClient(EC2Client);

describe("ec2 wrapper", () => {
  beforeEach(() => mock.reset());

  it("placeholder test", () => {
    expect(true).toBe(true);
  });
});
