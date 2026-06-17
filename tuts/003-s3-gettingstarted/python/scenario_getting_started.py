# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import uuid
import boto3
from s3_wrapper import S3Wrapper


def run_scenario():
    client = boto3.client("s3")
    wrapper = S3Wrapper(client)
    suffix = uuid.uuid4().hex[:8]
    print(f"Running S3 getting started scenario...")
    # TODO: implement setup, interact, teardown
    print("Scenario complete.")


if __name__ == "__main__":
    run_scenario()
