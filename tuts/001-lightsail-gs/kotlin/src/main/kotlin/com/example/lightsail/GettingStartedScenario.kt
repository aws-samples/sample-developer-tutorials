// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.lightsail

import aws.sdk.kotlin.services.lightsail.LightsailClient
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    LightsailClient { region = "us-east-1" }.use { client ->
        val wrapper = LightsailWrapper(client)
        println("Running Lightsail getting started scenario...")
        // TODO: setup, interact, teardown
    }
}
