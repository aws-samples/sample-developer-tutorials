# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import uuid
import boto3
from lightsail_wrapper import LightsailWrapper


def run_scenario():
    client = boto3.client("lightsail")
    wrapper = LightsailWrapper(client)
    suffix = uuid.uuid4().hex[:8]
    print(f"Running Lightsail getting started scenario...")
    # TODO: implement setup, interact, teardown
    print("Scenario complete.")


if __name__ == "__main__":
    run_scenario()
