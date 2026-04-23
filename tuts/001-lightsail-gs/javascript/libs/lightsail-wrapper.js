// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { LightsailClient, CreateDiskCommand, CreateInstancesCommand, DeleteDiskCommand, DeleteInstanceCommand, GetInstanceCommand } from "@aws-sdk/client-lightsail";

export const createInstances = async (client, params) => {
  const command = new CreateInstancesCommand(params);
  return client.send(command);
};
export const createDisk = async (client, params) => {
  const command = new CreateDiskCommand(params);
  return client.send(command);
};
export const getInstance = async (client, params) => {
  const command = new GetInstanceCommand(params);
  return client.send(command);
};
export const deleteInstance = async (client, params) => {
  const command = new DeleteInstanceCommand(params);
  return client.send(command);
};
export const deleteDisk = async (client, params) => {
  const command = new DeleteDiskCommand(params);
  return client.send(command);
};
