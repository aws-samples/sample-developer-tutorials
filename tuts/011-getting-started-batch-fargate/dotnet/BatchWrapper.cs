// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

using Amazon.Batch;
using Microsoft.Extensions.Logging;

public class BatchWrapper
{
    private readonly IAmazonBatch _client;
    private readonly ILogger<BatchWrapper> _logger;

    public BatchWrapper(IAmazonBatch client, ILogger<BatchWrapper> logger)
    {
        _client = client;
        _logger = logger;
    }

    // TODO: Add async wrapper methods matching CLI tutorial actions
}
