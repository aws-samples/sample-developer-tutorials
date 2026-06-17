# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import uuid
import boto3
from servicediscovery_wrapper import CloudMapAttrsWrapper


def run_scenario():
    client = boto3.client("servicediscovery")
    wrapper = CloudMapAttrsWrapper(client)
    print(f"Running CloudMapAttrs getting started scenario...")
    # TODO: implement setup, interact, teardown
    print("Scenario complete.")


if __name__ == "__main__":
    run_scenario()
