# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import uuid
import boto3
from ec2_wrapper import EC2Wrapper


def run_scenario():
    client = boto3.client("ec2")
    wrapper = EC2Wrapper(client)
    print(f"Running EC2 getting started scenario...")
    # TODO: implement setup, interact, teardown
    print("Scenario complete.")


if __name__ == "__main__":
    run_scenario()
