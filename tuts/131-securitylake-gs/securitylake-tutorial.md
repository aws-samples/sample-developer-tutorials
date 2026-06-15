# Getting started with Amazon Security Lake

## Prerequisites

Before you begin, ensure you have the following prerequisites in place:

- AWS CLI installed and configured
- Appropriate IAM permissions to create and manage Amazon Security Lake resources
- Optionally, a CloudFormation stack with necessary IAM roles if required

## Step 1: Create a Data Lake

**Create a Data Lake**

The following Python script creates an Amazon Security Lake Data Lake in the `us-east-1` region.

```python
import boto3
import json
import time
import os
import sys

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
suffix = str(int(time.time()))[-6:]
tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'securitylake-gs'}]

securitylake_client = boto3.client('securitylake')

# Step 1: Create Data Lake
print("Step 1: Creating Data Lake...")
response = securitylake_client.create_data_lake(
    Regions=['us-east-1'],
    Tags=tags
)
data_lake_arn = response['DataLakeArn']
print(f"Data Lake created with ARN: {data_lake_arn}")
```

**Expected Result**

The script will output the ARN of the created Data Lake, similar to:
```
Data Lake created with ARN: arn:aws:securitylake:us-east-1:123456789012:data-lake/abc123
```

## Step 2: Create an AWS Log Source

**Create an AWS Log Source**

The following Python script creates an AWS Log Source for Route53 Resolver.

```python
# Step 2: Create AWS Log Source
print("Step 2: Creating AWS Log Source...")
response = securitylake_client.create_aws_log_source(
    SourceType='ROUTE53_RESOLVER',
    SourceName=f'route53-resolver-{suffix}',
    Tags=tags
)
log_source_arn = response['LogSourceArn']
print(f"AWS Log Source created with ARN: {log_source_arn}")
```

**Expected Result**

The script will output the ARN of the created AWS Log Source, similar to:
```
AWS Log Source created with ARN: arn:aws:securitylake:us-east-1:123456789012:log-source/abc123
```

## Step 3: Create a Subscriber

**Create a Subscriber**

The following Python script creates a subscriber to receive data from the specified log source.

```python
# Step 3: Creating Subscriber...
response = securitylake_client.create_subscriber(
    Sources=['ROUTE53_RESOLVER'],
    DataAccessRoleArn=ROLE_ARN if ROLE_ARN else 'arn:aws:iam::123456789012:role/example-role',
    OutputConfiguration={
        'BucketConfiguration': {
            'BucketName': f'example-bucket-{suffix}',
            'Prefix':'securitylake/'
        }
    },
    Tags=tags
)
subscriber_id = response['SubscriberId']
print(f"Subscriber created with ID: {subscriber_id}")
```

**Expected Result**

The script will output the ID of the created subscriber, similar to:
```
Subscriber created with ID: abc123
```

## Clean up

To clean up the resources created during this tutorial, the script performs the following actions:

- Deletes the subscriber
- Deletes the AWS Log Source
- Deletes the Data Lake

**Clean up resources**

```python
# Cleanup
print("Cleaning up resources...")

# Delete Subscriber
print("Deleting Subscriber...")
securitylake_client.delete_subscriber(SubscriberId=subscriber_id)
print(f"Subscriber with ID {subscriber_id} deleted")

# Delete AWS Log Source
print("Deleting AWS Log Source...")
securitylake_client.delete_aws_log_source(SourceName=f'route53-resolver-{suffix}')
print(f"AWS Log Source route53-resolver-{suffix} deleted")

# Delete Data Lake
print("Deleting Data Lake...")
securitylake_client.delete_data_lake(DataLakeArn=data_lake_arn)
print(f"Data Lake with ARN {data_lake_arn} deleted")
```

**Expected Result**

The script will confirm the deletion of each resource.

## Next steps

- Explore additional log sources available in Amazon Security Lake
- Configure data subscribers for different use cases
- Integrate Security Lake with your security information and event management (SIEM) solution
