// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { ServiceDiscoveryClient, CreatePublicDnsNamespaceCommand, CreateServiceCommand, DeleteNamespaceCommand, DeleteServiceCommand } from "@aws-sdk/client-servicediscovery";

export const createNamespace = async (client, params) => {
  const command = new CreatePublicDnsNamespaceCommand(params);
  return client.send(command);
};
export const createService = async (client, params) => {
  const command = new CreateServiceCommand(params);
  return client.send(command);
};
export const deleteService = async (client, params) => {
  const command = new DeleteServiceCommand(params);
  return client.send(command);
};
export const deleteNamespace = async (client, params) => {
  const command = new DeleteNamespaceCommand(params);
  return client.send(command);
};
