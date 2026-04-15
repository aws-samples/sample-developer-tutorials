# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import uuid
import boto3
from cloudfront_wrapper import CloudFrontWrapper


def run_scenario():
    client = boto3.client("cloudfront")
    wrapper = CloudFrontWrapper(client)
    print(f"Running CloudFront getting started scenario...")
    # TODO: implement setup, interact, teardown
    print("Scenario complete.")


if __name__ == "__main__":
    run_scenario()
