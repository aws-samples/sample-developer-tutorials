# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import pytest
from botocore.stub import Stubber
import boto3
from servicediscovery_wrapper import CloudMapWrapper


@pytest.fixture
def servicediscovery_stubber():
    client = boto3.client("servicediscovery", region_name="us-east-1")
    with Stubber(client) as stubber:
        yield client, stubber


def test_wrapper_creates(capsys, servicediscovery_stubber):
    client, stubber = servicediscovery_stubber
    wrapper = CloudMapWrapper(client)
    # TODO: add stubbed responses and assertions
    assert wrapper is not None
