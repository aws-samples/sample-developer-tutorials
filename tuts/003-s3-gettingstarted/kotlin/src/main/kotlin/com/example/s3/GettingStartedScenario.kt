// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.s3

import aws.sdk.kotlin.services.s3.S3Client
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    S3Client { region = "us-east-1" }.use { client ->
        val wrapper = S3Wrapper(client)
        println("Running S3 getting started scenario...")
        // TODO: setup, interact, teardown
    }
}
