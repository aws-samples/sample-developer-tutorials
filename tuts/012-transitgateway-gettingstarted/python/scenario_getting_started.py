# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import uuid
import boto3
from ec2_wrapper import TransitGatewayWrapper


def run_scenario():
    client = boto3.client("ec2")
    wrapper = TransitGatewayWrapper(client)
    print(f"Running TransitGateway getting started scenario...")
    # TODO: implement setup, interact, teardown
    print("Scenario complete.")


if __name__ == "__main__":
    run_scenario()
