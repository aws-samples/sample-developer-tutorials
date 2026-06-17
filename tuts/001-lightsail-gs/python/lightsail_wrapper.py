# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import logging
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


class LightsailWrapper:
    def __init__(self, client):
        self.client = client

    def create_instances(self, instance_name, blueprint_id='amazon_linux_2023', bundle_id='nano_3_2'):
        """Calls lightsail:CreateInstances."""
        try:
            self.client.create_instances(instanceNames=[instance_name], blueprintId=blueprint_id, bundleId=bundle_id, availabilityZone=f'{self.client.meta.region_name}a')
            logger.info("CreateInstances succeeded.")
        except ClientError:
            logger.exception("CreateInstances failed.")
            raise

    def create_disk(self, disk_name, size_in_gb=8):
        """Calls lightsail:CreateDisk."""
        try:
            self.client.create_disk(diskName=disk_name, sizeInGb=size_in_gb, availabilityZone=f'{self.client.meta.region_name}a')
            logger.info("CreateDisk succeeded.")
        except ClientError:
            logger.exception("CreateDisk failed.")
            raise

    def get_instance(self, instance_name):
        """Calls lightsail:GetInstance."""
        try:
            return self.client.get_instance(instanceName=instance_name)['instance']
            logger.info("GetInstance succeeded.")
        except ClientError:
            logger.exception("GetInstance failed.")
            raise

    def delete_instance(self, instance_name):
        """Calls lightsail:DeleteInstance."""
        try:
            self.client.delete_instance(instanceName=instance_name)
            logger.info("DeleteInstance succeeded.")
        except ClientError:
            logger.exception("DeleteInstance failed.")
            raise

    def delete_disk(self, disk_name):
        """Calls lightsail:DeleteDisk."""
        try:
            self.client.delete_disk(diskName=disk_name)
            logger.info("DeleteDisk succeeded.")
        except ClientError:
            logger.exception("DeleteDisk failed.")
            raise
