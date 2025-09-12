# Getting started with AWS Elemental MediaConnect using the AWS CLI

This tutorial shows you how to use AWS Elemental MediaConnect with the AWS Command Line Interface (AWS CLI) to create and share flows. You'll learn how to create a flow, add an output, grant an entitlement, and clean up resources.

## Topics

- [Prerequisites](#prerequisites)
- [Verify access to AWS Elemental MediaConnect](#verify-access-to-aws-elemental-mediaconnect)
- [Create a flow](#create-a-flow)
- [Add an output](#add-an-output)
- [Grant an entitlement](#grant-an-entitlement)
- [Share details with affiliates](#share-details-with-affiliates)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. [Sufficient permissions](https://docs.aws.amazon.com/mediaconnect/latest/ug/security_iam_service-with-iam.html) to create and manage MediaConnect resources in your AWS account.
4. Completed the steps in [Setting up AWS Elemental MediaConnect](https://docs.aws.amazon.com/mediaconnect/latest/ug/setting-up.html).

This tutorial is based on a scenario where you want to:

- Ingest a live video stream of an awards show that is taking place in New York City
- Distribute your video to an affiliate in Boston who does not have an AWS account, and wants content sent to their on-premises encoder
- Share your video with an affiliate in Philadelphia who wants to use their AWS account to distribute the video to their three local stations

### Estimated time and cost

- **Time to complete**: Approximately 30 minutes
- **Cost**: The resources created in this tutorial will cost approximately $0.41 per hour while running, including:
  * Flow ingest: $0.08/hour
  * Flow egress: $0.08/hour
  * Data transfer (for a typical 5 Mbps stream): $0.25/hour

The tutorial includes cleanup instructions to help you avoid ongoing charges.

Before you start, set the `AWS_REGION` environment variable to the same Region that you configured the AWS CLI to use, if it's not already set. This environment variable is used in example commands to specify an availability zone for MediaConnect resources.

```
$ [ -z "${AWS_REGION}" ] && export AWS_REGION=$(aws configure get region)
```

Let's get started with creating and managing AWS Elemental MediaConnect resources using the CLI.

## Verify access to AWS Elemental MediaConnect

First, verify that you have access to the MediaConnect service by listing any existing flows.

**List existing flows**

```
$ aws mediaconnect list-flows
{
    "Flows": []
}
```

If you have the correct permissions, this command will return a list of existing flows or an empty list if you don't have any flows yet.

## Create a flow

Now, create an AWS Elemental MediaConnect flow to ingest your video from your on-premises encoder into the AWS Cloud. For this tutorial, we'll use the following details:

- Flow name: AwardsNYCShow
- Source name: AwardsNYCSource
- Source protocol: Zixi push
- Zixi stream ID: ZixiAwardsNYCFeed
- CIDR block sending the content: 10.24.34.0/23
- Source encryption: None

**Create a flow**

First, you need to get an availability zone in your current region:

```
$ AVAILABILITY_ZONE=$(aws ec2 describe-availability-zones --query "AvailabilityZones[0].ZoneName" --output text)
$ echo $AVAILABILITY_ZONE
us-east-2a
```

Now, create the flow using the availability zone:

```
$ aws mediaconnect create-flow \
    --availability-zone $AVAILABILITY_ZONE \
    --name AwardsNYCShow \
    --source Name=AwardsNYCSource,Protocol=zixi-push,WhitelistCidr=10.24.34.0/23,StreamId=ZixiAwardsNYCFeed
{
    "Flow": {
        "AvailabilityZone": "us-east-2a",
        "EgressIp": "203.0.113.242",
        "Entitlements": [],
        "FlowArn": "arn:aws:mediaconnect:us-east-2:123456789012:flow:1-abcd1234-b786ff4d2b36:AwardsNYCShow",
        "MediaStreams": [],
        "Name": "AwardsNYCShow",
        "Outputs": [],
        "Source": {
            "IngestIp": "203.0.113.242",
            "IngestPort": 2088,
            "Name": "AwardsNYCSource",
            "SourceArn": "arn:aws:mediaconnect:us-east-2:123456789012:source:1-abcd1234-b786ff4d2b36:AwardsNYCSource",
            "Transport": {
                "Protocol": "zixi-push",
                "StreamId": "ZixiAwardsNYCFeed"
            },
            "WhitelistCidr": "10.24.34.0/23"
        },
        "Sources": [
            {
                "IngestIp": "203.0.113.242",
                "IngestPort": 2088,
                "Name": "AwardsNYCSource",
                "SourceArn": "arn:aws:mediaconnect:us-east-2:123456789012:source:1-abcd1234-b786ff4d2b36:AwardsNYCSource",
                "Transport": {
                    "Protocol": "zixi-push",
                    "StreamId": "ZixiAwardsNYCFeed"
                },
                "WhitelistCidr": "10.24.34.0/23"
            }
        ],
        "Status": "STANDBY"
    }
}
```

Save the Flow ARN from the output as you'll need it for subsequent commands:

```
$ FLOW_ARN="arn:aws:mediaconnect:us-east-2:123456789012:flow:1-abcd1234-b786ff4d2b36:AwardsNYCShow"
```

## Add an output

To send content to your affiliate in Boston, add an output to your flow. This output will send your video to your Boston affiliate's on-premises encoder. We'll use these details:

- Output name: AwardsNYCOutput
- Output protocol: Zixi push
- Zixi stream ID: ZixiAwardsOutput
- IP address of the Boston affiliate's on-premises encoder: 198.51.100.11
- Port: 1024
- Output encryption: None

**Add an output to the flow**

```
$ aws mediaconnect add-flow-outputs \
    --flow-arn $FLOW_ARN \
    --outputs Name=AwardsNYCOutput,Protocol=zixi-push,Destination=198.51.100.11,Port=1024,StreamId=ZixiAwardsOutput
{
    "FlowArn": "arn:aws:mediaconnect:us-east-2:123456789012:flow:1-abcd1234-b786ff4d2b36:AwardsNYCShow",
    "Outputs": [
        {
            "Destination": "198.51.100.11",
            "Name": "AwardsNYCOutput",
            "OutputArn": "arn:aws:mediaconnect:us-east-2:123456789012:output:1-abcd1234-b786ff4d2b36:AwardsNYCOutput",
            "Port": 1024,
            "Transport": {
                "MaxLatency": 6000,
                "Protocol": "zixi-push",
                "StreamId": "ZixiAwardsOutput"
            },
            "OutputStatus": "ENABLED"
        }
    ]
}
```

## Grant an entitlement

Grant an entitlement to allow your Philadelphia affiliate to use your content as the source for their AWS Elemental MediaConnect flow. We'll use these details:

- Entitlement name: PhillyTeam
- Philadelphia affiliate's AWS account ID: 222233334444
- Output encryption: None

**Grant an entitlement**

```
$ aws mediaconnect grant-flow-entitlements \
    --flow-arn $FLOW_ARN \
    --entitlements Name=PhillyTeam,Subscribers=222233334444
{
    "Entitlements": [
        {
            "EntitlementArn": "arn:aws:mediaconnect:us-east-2:123456789012:entitlement:1-abcd1234-b786ff4d2b36:PhillyTeam",
            "EntitlementStatus": "ENABLED",
            "Name": "PhillyTeam",
            "Subscribers": [
                "222233334444"
            ]
        }
    ],
    "FlowArn": "arn:aws:mediaconnect:us-east-2:123456789012:flow:1-abcd1234-b786ff4d2b36:AwardsNYCShow"
}
```

Save the Entitlement ARN from the output:

```
$ ENTITLEMENT_ARN="arn:aws:mediaconnect:us-east-2:123456789012:entitlement:1-abcd1234-b786ff4d2b36:PhillyTeam"
```

## Share details with affiliates

Now that you've created your flow with an output for your Boston affiliate and an entitlement for your Philadelphia affiliate, you need to share details about the flow.

**Get entitlement details**

To retrieve the entitlement details to share with your Philadelphia affiliate, use the describe-flow command:

```
$ aws mediaconnect describe-flow --flow-arn $FLOW_ARN --query "Flow.Entitlements"
[
    {
        "EntitlementArn": "arn:aws:mediaconnect:us-east-2:123456789012:entitlement:1-abcd1234-b786ff4d2b36:PhillyTeam",
        "EntitlementStatus": "ENABLED",
        "Name": "PhillyTeam",
        "Subscribers": [
            "222233334444"
        ]
    }
]
```

Your Boston affiliate will receive the flow on their on-premises encoder. The details of where to send your video stream were provided by your Boston affiliate, and you don't need to provide any other information. After you start your flow, the content will be sent to the IP address that you specified when you created the flow.

Your Philadelphia affiliate must create their own AWS Elemental MediaConnect flow, using your flow as the source. You must provide them with:

1. The entitlement ARN (which you saved in the previous step)
2. The AWS Region where you created the flow

To start the flow so that content begins flowing to your affiliates, run:

```
$ aws mediaconnect start-flow --flow-arn $FLOW_ARN
{
    "FlowArn": "arn:aws:mediaconnect:us-east-2:123456789012:flow:1-abcd1234-b786ff4d2b36:AwardsNYCShow",
    "Status": "STARTING"
}
```

## Clean up resources

To avoid unnecessary charges, stop and delete the flow when it's no longer needed.

**Check flow status**

Before stopping the flow, check its current status:

```
$ aws mediaconnect describe-flow --flow-arn $FLOW_ARN --query "Flow.Status" --output text
ACTIVE
```

**Stop the flow**

```
$ aws mediaconnect stop-flow --flow-arn $FLOW_ARN
{
    "FlowArn": "arn:aws:mediaconnect:us-east-2:123456789012:flow:1-abcd1234-b786ff4d2b36:AwardsNYCShow",
    "Status": "STOPPING"
}
```

Wait for the flow to stop before deleting it. You can check the status periodically:

```
$ aws mediaconnect describe-flow --flow-arn $FLOW_ARN --query "Flow.Status" --output text
STOPPING
```

Once the status shows as `STANDBY`, you can delete the flow:

```
$ aws mediaconnect delete-flow --flow-arn $FLOW_ARN
{
    "FlowArn": "arn:aws:mediaconnect:us-east-2:123456789012:flow:1-abcd1234-b786ff4d2b36:AwardsNYCShow",
    "Status": "DELETING"
}
```

## Going to production

This tutorial demonstrates the basic functionality of AWS Elemental MediaConnect for educational purposes. When implementing MediaConnect in a production environment, consider the following best practices:

### Security considerations

1. **Content encryption**: For sensitive content, enable encryption using AWS Key Management Service (KMS) or static key encryption. See [Encrypting your content in AWS Elemental MediaConnect](https://docs.aws.amazon.com/mediaconnect/latest/ug/encryption.html).

2. **IAM permissions**: Implement least-privilege IAM policies for users and roles that interact with MediaConnect. See [Identity-based policy examples for AWS Elemental MediaConnect](https://docs.aws.amazon.com/mediaconnect/latest/ug/security_iam_id-based-policy-examples.html).

3. **Network security**: Consider using VPC interface endpoints for enhanced network security. See [AWS Elemental MediaConnect and interface VPC endpoints](https://docs.aws.amazon.com/mediaconnect/latest/ug/vpc-interface-endpoints.html).

### Reliability considerations

1. **Source failover**: Configure source failover to ensure high availability. See [Source failover in AWS Elemental MediaConnect](https://docs.aws.amazon.com/mediaconnect/latest/ug/sources-failover.html).

2. **Monitoring**: Set up CloudWatch alarms to monitor your flows and receive notifications about issues. See [Monitoring AWS Elemental MediaConnect](https://docs.aws.amazon.com/mediaconnect/latest/ug/monitoring.html).

For comprehensive guidance on building production-ready architectures, refer to:

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Media & Entertainment on AWS](https://aws.amazon.com/media/)
- [AWS Media Services](https://aws.amazon.com/media-services/)

## Next steps

Now that you've learned the basics of using AWS Elemental MediaConnect with the AWS CLI, you can explore more advanced features:

- Learn how to [encrypt your content](https://docs.aws.amazon.com/mediaconnect/latest/ug/encryption.html) for secure transmission
- Explore [monitoring options](https://docs.aws.amazon.com/mediaconnect/latest/ug/monitoring.html) for your MediaConnect flows
- Set up [failover sources](https://docs.aws.amazon.com/mediaconnect/latest/ug/sources-failover.html) for high availability
- Learn about [MediaConnect gateways](https://docs.aws.amazon.com/mediaconnect/latest/ug/gateways.html) for cloud-based video processing
