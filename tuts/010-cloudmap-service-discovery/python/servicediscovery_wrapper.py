# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import logging
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


class CloudMapWrapper:
    def __init__(self, client):
        self.client = client

    def create_namespace(self, name):
        """Calls servicediscovery:CreatePublicDnsNamespace."""
        try:
            return self.client.create_public_dns_namespace(Name=name)['OperationId']
            logger.info("CreatePublicDnsNamespace succeeded.")
        except ClientError:
            logger.exception("CreatePublicDnsNamespace failed.")
            raise

    def create_service(self, name, namespace_id):
        """Calls servicediscovery:CreateService."""
        try:
            return self.client.create_service(Name=name, NamespaceId=namespace_id, DnsConfig={'DnsRecords': [{'Type': 'A', 'TTL': 60}]})['Service']['Id']
            logger.info("CreateService succeeded.")
        except ClientError:
            logger.exception("CreateService failed.")
            raise

    def delete_service(self, service_id):
        """Calls servicediscovery:DeleteService."""
        try:
            self.client.delete_service(Id=service_id)
            logger.info("DeleteService succeeded.")
        except ClientError:
            logger.exception("DeleteService failed.")
            raise

    def delete_namespace(self, namespace_id):
        """Calls servicediscovery:DeleteNamespace."""
        try:
            self.client.delete_namespace(Id=namespace_id)
            logger.info("DeleteNamespace succeeded.")
        except ClientError:
            logger.exception("DeleteNamespace failed.")
            raise
