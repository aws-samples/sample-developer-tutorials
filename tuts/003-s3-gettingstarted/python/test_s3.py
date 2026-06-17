# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import pytest
from botocore.stub import Stubber
import boto3
from s3_wrapper import S3Wrapper


@pytest.fixture
def s3_stubber():
    client = boto3.client("s3", region_name="us-east-1")
    with Stubber(client) as stubber:
        yield client, stubber


def test_wrapper_creates(capsys, s3_stubber):
    client, stubber = s3_stubber
    wrapper = S3Wrapper(client)
    # TODO: add stubbed responses and assertions
    assert wrapper is not None
