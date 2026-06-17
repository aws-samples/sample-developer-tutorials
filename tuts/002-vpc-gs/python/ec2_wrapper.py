# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import logging
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


class EC2Wrapper:
    def __init__(self, client):
        self.client = client

    # TODO: Add wrapper methods matching the CLI tutorial actions
