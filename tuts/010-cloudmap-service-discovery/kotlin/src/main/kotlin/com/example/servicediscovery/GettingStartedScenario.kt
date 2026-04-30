// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.servicediscovery

import aws.sdk.kotlin.services.servicediscovery.CloudMapClient
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    CloudMapClient { region = "us-east-1" }.use { client ->
        val wrapper = CloudMapWrapper(client)
        println("Running CloudMap getting started scenario...")
        // TODO: setup, interact, teardown
    }
}
