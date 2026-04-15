// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.ec2

import aws.sdk.kotlin.services.ec2.Ec2Client
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    Ec2Client { region = "us-east-1" }.use { client ->
        val wrapper = Ec2Wrapper(client)
        println("Running Ec2 getting started scenario...")
        // TODO: setup, interact, teardown
    }
}
