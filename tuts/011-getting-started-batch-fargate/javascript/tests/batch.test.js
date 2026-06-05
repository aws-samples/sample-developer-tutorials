// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { describe, it, expect, beforeEach } from "vitest";
import { mockClient } from "aws-sdk-client-mock";
import { BatchClient } from "@aws-sdk/client-batch";

const mock = mockClient(BatchClient);

describe("batch wrapper", () => {
  beforeEach(() => mock.reset());

  it("placeholder test", () => {
    expect(true).toBe(true);
  });
});
