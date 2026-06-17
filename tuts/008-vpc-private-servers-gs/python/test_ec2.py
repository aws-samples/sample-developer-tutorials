# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import pytest
from botocore.stub import Stubber
import boto3
from ec2_wrapper import VPCPrivateWrapper


@pytest.fixture
def stubber():
    client = boto3.client("ec2", region_name="us-east-1")
    with Stubber(client) as stubber:
        yield client, stubber


def test_wrapper_creates(stubber):
    client, stub = stubber
    wrapper = VPCPrivateWrapper(client)
    assert wrapper is not None
