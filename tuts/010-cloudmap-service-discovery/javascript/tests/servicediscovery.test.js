// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { describe, it, expect, beforeEach } from "vitest";
import { mockClient } from "aws-sdk-client-mock";
import { ServiceDiscoveryClient } from "@aws-sdk/client-servicediscovery";

const mock = mockClient(ServiceDiscoveryClient);

describe("servicediscovery wrapper", () => {
  beforeEach(() => mock.reset());

  it("placeholder test", () => {
    expect(true).toBe(true);
  });
});
