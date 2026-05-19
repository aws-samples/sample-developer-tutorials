# Getting started with AWS Elemental MediaPackage v2

## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI installed and configured
- Appropriate IAM permissions to create and manage MediaPackage v2 resources
- Optionally, a CloudFormation stack with necessary IAM roles if required

## Step 1: Create a Channel Group

**Create a Channel Group**

The following Python script creates a Channel Group in AWS Elemental MediaPackage v2. This is the first step in setting up your media workflow.

```python
import boto3
import time
import os

client = boto3.client('mediapackagev2')
suffix = str(int(time.time()))[-6:]

channel_group_name = f'channel-group-{suffix}'
response = client.create_channel_group(ChannelGroupName=channel_group_name, Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'mediapackagev2-gs'}])
print(f"Channel Group created with ARN: {response['Arn']}")
```

**Expected Result:**

You should see an output similar to:

```
Channel Group created with ARN: arn:aws:mediapackagev2:us-west-2:123456789012:channel-group/channel-group-abc123
```

## Step 2: Create a Channel

**Create a Channel**

The following Python script creates a Channel within the Channel Group you just created.

```python
channel_name = f'channel-{suffix}'
response = client.create_channel(ChannelGroupName=channel_group_name, ChannelName=channel_name, Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'mediapackagev2-gs'}])
print(f"Channel created with ARN: {response['Arn']}")
```

**Expected Result:**

You should see an output similar to:

```
Channel created with ARN: arn:aws:mediapackagev2:us-west-2:123456789012:channel-group/channel-group-abc123/channel/channel-abc123
```

## Step 3: Create an Origin Endpoint

**Create an Origin Endpoint**

The following Python script creates an Origin Endpoint within the Channel. This endpoint will be used to serve your media content.

```python
origin_endpoint_name = f'origin-endpoint-{suffix}'
response = client.create_origin_endpoint(ChannelGroupName=channel_group_name, ChannelName=channel_name, OriginEndpointName=origin_endpoint_name, ContainerType='HLS', Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'mediapackagev2-gs'}])
print(f"Origin Endpoint created with ARN: {response['Arn']}")
```

**Expected Result:**

You should see an output similar to:

```
Origin Endpoint created with ARN: arn:aws:mediapackagev2:us-west-2:123456789012:channel-group/channel-group-abc123/channel/channel-abc123/origin-endpoint/origin-endpoint-abc123
```

## Clean up

To avoid unnecessary charges, clean up the resources you created. The following Python script deletes the Origin Endpoint, Channel, and Channel Group.

**Clean up resources**

```python
print("Cleaning up resources...")

# Delete Origin Endpoint
print(f"Deleting Origin Endpoint: {origin_endpoint_name}")
client.delete_origin_endpoint(ChannelGroupName=channel_group_name, ChannelName=channel_name, OriginEndpointName=origin_endpoint_name)

# Delete Channel
print(f"Deleting Channel: {channel_name}")
client.delete_channel(ChannelGroupName=channel_group_name, ChannelName=channel_name)

# Delete Channel Group
print(f"Deleting Channel Group: {channel_group_name}")
client.delete_channel_group(ChannelGroupName=channel_group_name)

print("PASS")
```

**Expected Result:**

You should see an output indicating that all resources have been deleted successfully.

## Next steps

- Explore [AWS Elemental MediaPackage v2 documentation](https://docs.aws.amazon.com/mediapackage/latest/ug/what-is.html) for more features.
- Learn how to [configure ad insertion](https://docs.aws.amazon.com/mediapackage/latest/ug/ad-insert.html) in your media workflow.
- Discover how to [integrate with AWS Elemental MediaTailor](https://docs.aws.amazon.com/mediatailor/latest/ug/what-is.html) for personalized ad experiences.
