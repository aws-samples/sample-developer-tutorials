# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import pytest
from botocore.stub import Stubber
import boto3
from lightsail_wrapper import LightsailWrapper


@pytest.fixture
def lightsail_stubber():
    client = boto3.client("lightsail", region_name="us-east-1")
    with Stubber(client) as stubber:
        yield client, stubber


def test_wrapper_creates(capsys, lightsail_stubber):
    client, stubber = lightsail_stubber
    wrapper = LightsailWrapper(client)
    # TODO: add stubbed responses and assertions
    assert wrapper is not None
