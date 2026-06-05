// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { describe, it, expect, beforeEach } from "vitest";
import { mockClient } from "aws-sdk-client-mock";
import { S3Client } from "@aws-sdk/client-s3";

const mock = mockClient(S3Client);

describe("s3 wrapper", () => {
  beforeEach(() => mock.reset());

  it("placeholder test", () => {
    expect(true).toBe(true);
  });
});
