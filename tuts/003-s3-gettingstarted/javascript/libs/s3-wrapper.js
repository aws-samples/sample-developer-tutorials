// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { S3Client, CopyObjectCommand, CreateBucketCommand, DeleteBucketCommand, DeleteObjectsCommand, GetObjectCommand, ListObjectsV2Command, PutObjectCommand } from "@aws-sdk/client-s3";

export const createBucket = async (client, params) => {
  const command = new CreateBucketCommand(params);
  return client.send(command);
};
export const putObject = async (client, params) => {
  const command = new PutObjectCommand(params);
  return client.send(command);
};
export const getObject = async (client, params) => {
  const command = new GetObjectCommand(params);
  return client.send(command);
};
export const copyObject = async (client, params) => {
  const command = new CopyObjectCommand(params);
  return client.send(command);
};
export const listObjects = async (client, params) => {
  const command = new ListObjectsV2Command(params);
  return client.send(command);
};
export const deleteObjects = async (client, params) => {
  const command = new DeleteObjectsCommand(params);
  return client.send(command);
};
export const deleteBucket = async (client, params) => {
  const command = new DeleteBucketCommand(params);
  return client.send(command);
};
