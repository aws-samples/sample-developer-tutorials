// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { BatchClient, CreateComputeEnvironmentCommand, CreateJobQueueCommand, DeleteComputeEnvironmentCommand, DeleteJobQueueCommand } from "@aws-sdk/client-batch";

export const createComputeEnv = async (client, params) => {
  const command = new CreateComputeEnvironmentCommand(params);
  return client.send(command);
};
export const createJobQueue = async (client, params) => {
  const command = new CreateJobQueueCommand(params);
  return client.send(command);
};
export const deleteJobQueue = async (client, params) => {
  const command = new DeleteJobQueueCommand(params);
  return client.send(command);
};
export const deleteComputeEnv = async (client, params) => {
  const command = new DeleteComputeEnvironmentCommand(params);
  return client.send(command);
};
