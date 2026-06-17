# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import pytest
from botocore.stub import Stubber
import boto3
from batch_wrapper import BatchWrapper


@pytest.fixture
def batch_stubber():
    client = boto3.client("batch", region_name="us-east-1")
    with Stubber(client) as stubber:
        yield client, stubber


def test_wrapper_creates(capsys, batch_stubber):
    client, stubber = batch_stubber
    wrapper = BatchWrapper(client)
    # TODO: add stubbed responses and assertions
    assert wrapper is not None
