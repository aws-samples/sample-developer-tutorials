// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.example.cloudfront

import aws.sdk.kotlin.services.cloudfront.CloudFrontClient
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    CloudFrontClient { region = "us-east-1" }.use { client ->
        val wrapper = CloudFrontWrapper(client)
        println("Running CloudFront getting started scenario...")
        // TODO: setup, interact, teardown
    }
}
