# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import logging
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


class S3Wrapper:
    def __init__(self, client):
        self.client = client

    def create_bucket(self, bucket_name):
        """Calls s3:CreateBucket."""
        try:
            self.client.create_bucket(Bucket=bucket_name)
            logger.info("CreateBucket succeeded.")
        except ClientError:
            logger.exception("CreateBucket failed.")
            raise

    def put_object(self, bucket_name, key, body):
        """Calls s3:PutObject."""
        try:
            self.client.put_object(Bucket=bucket_name, Key=key, Body=body)
            logger.info("PutObject succeeded.")
        except ClientError:
            logger.exception("PutObject failed.")
            raise

    def get_object(self, bucket_name, key):
        """Calls s3:GetObject."""
        try:
            return self.client.get_object(Bucket=bucket_name, Key=key)['Body'].read()
            logger.info("GetObject succeeded.")
        except ClientError:
            logger.exception("GetObject failed.")
            raise

    def copy_object(self, src_bucket, src_key, dst_bucket, dst_key):
        """Calls s3:CopyObject."""
        try:
            self.client.copy_object(CopySource={'Bucket': src_bucket, 'Key': src_key}, Bucket=dst_bucket, Key=dst_key)
            logger.info("CopyObject succeeded.")
        except ClientError:
            logger.exception("CopyObject failed.")
            raise

    def list_objects(self, bucket_name):
        """Calls s3:ListObjectsV2."""
        try:
            return self.client.list_objects_v2(Bucket=bucket_name).get('Contents', [])
            logger.info("ListObjectsV2 succeeded.")
        except ClientError:
            logger.exception("ListObjectsV2 failed.")
            raise

    def delete_objects(self, bucket_name, keys):
        """Calls s3:DeleteObjects."""
        try:
            self.client.delete_objects(Bucket=bucket_name, Delete={'Objects': [{'Key': k} for k in keys]})
            logger.info("DeleteObjects succeeded.")
        except ClientError:
            logger.exception("DeleteObjects failed.")
            raise

    def delete_bucket(self, bucket_name):
        """Calls s3:DeleteBucket."""
        try:
            self.client.delete_bucket(Bucket=bucket_name)
            logger.info("DeleteBucket succeeded.")
        except ClientError:
            logger.exception("DeleteBucket failed.")
            raise
