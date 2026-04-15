// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

using Amazon.Ec2;
using Microsoft.Extensions.Logging;

public class Ec2Wrapper
{
    private readonly IAmazonEc2 _client;
    private readonly ILogger<Ec2Wrapper> _logger;

    public Ec2Wrapper(IAmazonEc2 client, ILogger<Ec2Wrapper> logger)
    {
        _client = client;
        _logger = logger;
    }

    // TODO: Add async wrapper methods matching CLI tutorial actions
}
