// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

using Amazon.Lightsail;
using Microsoft.Extensions.Logging;

public class LightsailWrapper
{
    private readonly IAmazonLightsail _client;
    private readonly ILogger<LightsailWrapper> _logger;

    public LightsailWrapper(IAmazonLightsail client, ILogger<LightsailWrapper> logger)
    {
        _client = client;
        _logger = logger;
    }

    // TODO: Add async wrapper methods matching CLI tutorial actions
}
