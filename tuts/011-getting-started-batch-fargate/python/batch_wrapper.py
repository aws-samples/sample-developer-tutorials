# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import logging
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


class BatchWrapper:
    def __init__(self, client):
        self.client = client

    def create_compute_environment(self, name, subnets, security_groups, service_role):
        """Calls batch:CreateComputeEnvironment."""
        try:
            return self.client.create_compute_environment(computeEnvironmentName=name, type='MANAGED', computeResources={'type': 'FARGATE', 'maxvCpus': 4, 'subnets': subnets, 'securityGroupIds': security_groups}, serviceRole=service_role)['computeEnvironmentArn']
            logger.info("CreateComputeEnvironment succeeded.")
        except ClientError:
            logger.exception("CreateComputeEnvironment failed.")
            raise

    def create_job_queue(self, name, compute_env_arn):
        """Calls batch:CreateJobQueue."""
        try:
            return self.client.create_job_queue(jobQueueName=name, priority=1, computeEnvironmentOrder=[{'order': 1, 'computeEnvironment': compute_env_arn}])['jobQueueArn']
            logger.info("CreateJobQueue succeeded.")
        except ClientError:
            logger.exception("CreateJobQueue failed.")
            raise

    def delete_job_queue(self, name):
        """Calls batch:DeleteJobQueue."""
        try:
            self.client.delete_job_queue(jobQueue=name)
            logger.info("DeleteJobQueue succeeded.")
        except ClientError:
            logger.exception("DeleteJobQueue failed.")
            raise

    def delete_compute_environment(self, name):
        """Calls batch:DeleteComputeEnvironment."""
        try:
            self.client.delete_compute_environment(computeEnvironment=name)
            logger.info("DeleteComputeEnvironment succeeded.")
        except ClientError:
            logger.exception("DeleteComputeEnvironment failed.")
            raise
