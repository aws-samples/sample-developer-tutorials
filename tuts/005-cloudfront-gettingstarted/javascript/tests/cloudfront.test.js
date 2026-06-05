// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { describe, it, expect, beforeEach } from "vitest";
import { mockClient } from "aws-sdk-client-mock";
import { CloudFrontClient } from "@aws-sdk/client-cloudfront";

const mock = mockClient(CloudFrontClient);

describe("cloudfront wrapper", () => {
  beforeEach(() => mock.reset());

  it("placeholder test", () => {
    expect(true).toBe(true);
  });
});
