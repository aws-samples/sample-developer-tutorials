# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import uuid
import boto3
from batch_wrapper import BatchWrapper


def run_scenario():
    client = boto3.client("batch")
    wrapper = BatchWrapper(client)
    suffix = uuid.uuid4().hex[:8]
    print(f"Running Batch getting started scenario...")
    # TODO: implement setup, interact, teardown
    print("Scenario complete.")


if __name__ == "__main__":
    run_scenario()
