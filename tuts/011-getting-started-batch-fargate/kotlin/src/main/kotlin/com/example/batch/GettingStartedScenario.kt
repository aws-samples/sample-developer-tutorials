// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.batch

import aws.sdk.kotlin.services.batch.BatchClient
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    BatchClient { region = "us-east-1" }.use { client ->
        val wrapper = BatchWrapper(client)
        println("Running Batch getting started scenario...")
        // TODO: setup, interact, teardown
    }
}
