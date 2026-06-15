# Getting started with Amazon EventBridge Pipes

## Prerequisites

Before you begin, ensure you have the following prerequisites in place:

- AWS CLI installed and configured.
- Appropriate IAM permissions to create and manage EventBridge Pipes.
- An IAM role with the necessary permissions for EventBridge Pipes. If you don't have one, you can create it using AWS CloudFormation or the AWS Management Console.

## Step 1: Create a Pipe

**Create a Pipe using Python**

This script creates a new EventBridge Pipe with a unique name, using an IAM role for permissions. It also adds tags to the pipe for categorization.

```python
import boto3
import json
import time
import os
import sys

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
suffix = str(int(time.time()))[-6:]
tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'pipes-gs'}]

client = boto3.client('pipes')

# Step 1: Create Pipe
print("Step 1: Creating a Pipe...")
pipe_name = f"tutorial-pipe-{suffix}"
response = client.create_pipe(
    Name=pipe_name,
    RoleArn=ROLE_ARN if ROLE_ARN else f"arn:aws:iam::{boto3.client('sts').get_caller_identity().get('Account')}:role/service-role/EventBridgePipesRole",
    Source='ExampleSource',
    Target='ExampleTarget',
    Description='Tutorial Pipe',
    Tags=tags
)
pipe_arn = response['Arn']
print(f"Pipe created with ARN: {pipe_arn}")
```

After running the script, you should see output similar to this:

```
Step 1: Creating a Pipe...
Pipe created with ARN: arn:aws:pipes:us-east-1:123456789012:pipe/tutorial-pipe-abc123
```

## Step 2: Verify Pipe Creation

**Verify the Pipe Creation using Python**

This script verifies that the pipe was created successfully by describing the pipe.

```python
# Step 2: Verify Pipe Creation
print("Step 2: Verifying Pipe creation...")
response = client.describe_pipe(Name=pipe_name)
print(f"Pipe description: {json.dumps(response, indent=2)}")
```

The output should display the details of the created pipe:

```json
{
  "Name": "tutorial-pipe-abc123",
  "Arn": "arn:aws:pipes:us-east-1:123456789012:pipe/tutorial-pipe-abc123",
  "RoleArn": "arn:aws:iam::123456789012:role/service-role/EventBridgePipesRole",
  "Source": "ExampleSource",
  "Target": "ExampleTarget",
  "Description": "Tutorial Pipe",
  "Tags": {
    "project": "doc-smith",
    "tutorial": "pipes-gs"
  }
}
```

## Step 3: List Pipes

**List all Pipes using Python**

This script lists all the pipes in your account to ensure the new pipe appears in the list.

```python
# Step 3: List Pipes
print("Step 3: Listing Pipes...")
response = client.list_pipes()
print(f"List of Pipes: {json.dumps(response, indent=2)}")
```

The output should include the newly created pipe in the list:

```json
{
  "Pipes": [
    {
      "Name": "tutorial-pipe-abc123",
      "Arn": "arn:aws:pipes:us-east-1:123456789012:pipe/tutorial-pipe-abc123",
      "RoleArn": "arn:aws:iam::123456789012:role/service-role/EventBridgePipesRole",
      "Source": "ExampleSource",
      "Target": "ExampleTarget",
      "Description": "Tutorial Pipe",
      "Tags": {
        "project": "doc-smith",
        "tutorial": "pipes-gs"
      }
    }
  ]
}
```

## Clean up

**Clean up resources using Python**

This script deletes the created pipe to ensure no unnecessary resources remain.

```python
# Step 4: Clean up
print("Step 4: Cleaning up resources...")
print("Deleting Pipe...")
client.delete_pipe(Name=pipe_name)
print("Wait for Pipe to be deleted...")
time.sleep(10)  # Wait for deletion to complete
print('PASS')
```

After running the cleanup script, the pipe will be deleted, and you should see:

```
Step 4: Cleaning up resources...
Deleting Pipe...
Wait for Pipe to be deleted...
PASS
```

## Next steps

- Explore more complex EventBridge Pipes configurations.
- Integrate EventBridge Pipes with other AWS services.
- Monitor your pipes using CloudWatch.
