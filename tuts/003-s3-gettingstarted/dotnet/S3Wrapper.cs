// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

using Amazon.S3;
using Microsoft.Extensions.Logging;

public class S3Wrapper
{
    private readonly IAmazonS3 _client;
    private readonly ILogger<S3Wrapper> _logger;

    public S3Wrapper(IAmazonS3 client, ILogger<S3Wrapper> logger)
    {
        _client = client;
        _logger = logger;
    }

    // TODO: Add async wrapper methods matching CLI tutorial actions
}
