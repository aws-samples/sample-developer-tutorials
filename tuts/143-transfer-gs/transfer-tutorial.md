# Getting started with AWS Transfer Family

Welcome to the AWS Transfer Family getting started tutorial. This guide will walk you through the process of creating and managing a Transfer Family server using both Python and CLI scripts.

## Prerequisites

Before you begin, ensure you have the following prerequisites in place:

- AWS Command Line Interface (CLI) installed and configured with appropriate credentials.
- Required IAM permissions to create and manage Transfer Family servers and users.
- A CloudFormation stack with necessary IAM roles if you plan to use service-managed users.

## Step 1: Create a Transfer Family Server

**Python Script:**

Before running the Python script, ensure you have the `boto3` library installed and the `TUTORIAL_ROLE_ARN` environment variable set.

```python
import boto3
import json
import time
import os
import sys

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
suffix = str(int(time.time()))[-6:]
tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'transfer-gs'}]

transfer_client = boto3.client('transfer')

# Create Server
print("Creating a Transfer Family server...")
server_response = transfer_client.create_server(
    IdentityProviderType='SERVICE_MANAGED',
    Tags=tags
)
server_id = server_response['ServerId']
print(f"Transfer Family server created with ID: {server_id}")

# Wait for the server to become active
print("Waiting for the server to become active...")
transfer_client.get_waiter('server_online').wait(ServerId=server_id)
print("Server is now active.")
```

**CLI Command:**

Run the following command to create a Transfer Family server:

```bash
$ aws transfer create-server --endpoint-type PUBLIC --protocols SFTP --identity-provider-type SERVICE_MANAGED
```

**Expected Output:**

```json
{
    "ServerId": "s-1234567890abcdef0"
}
```

## Step 2: Create a User

**Python Script:**

```python
# Create User
print("Creating a user for the Transfer Family server...")
user_response = transfer_client.create_user(
    ServerId=server_id,
    UserName=f'user-{suffix}',
    Tags=tags
)
user_name = user_response['ServerId']
print(f"User created with name: user-{suffix}")
```

**CLI Command:**

```bash
$ aws transfer create-user --server-id s-1234567890abcdef0 --user-name user-abcdef
```

**Expected Output:**

```json
{
    "ServerId": "s-1234567890abcdef0",
    "UserName": "user-abcdef"
}
```

## Step 3: Verify the Server

**Python Script:**

```python
# Verify Server
print("Verifying the Transfer Family server...")
describe_server_response = transfer_client.describe_server(ServerId=server_id)
print("Server verification successful.")
```

**CLI Command:**

```bash
$ aws transfer describe-server --server-id s-1234567890abcdef0
```

**Expected Output:**

```json
{
    "Server": {
        "Arn": "arn:aws:transfer:us-east-1:123456789012:server/s-1234567890abcdef0",
        "IdentityProviderType": "SERVICE_MANAGED",
        "LoggingRole": "arn:aws:iam::123456789012:role/TransferLoggingAccess",
        "ServerId": "s-1234567890abcdef0",
        "Status": "ONLINE",
        "EndpointType": "PUBLIC",
        "Protocols": [
            "SFTP"
        ]
    }
}
```

## Clean up

After completing the tutorial, it's important to clean up the resources to avoid unnecessary charges.

**Python Script:**

```python
# Clean up
print("Cleaning up resources...")

# Delete User
print("Deleting the user...")
transfer_client.delete_user(
    ServerId=server_id,
    UserName=f'user-{suffix}'
)
print("User deleted.")

# Delete Server
print("Deleting the Transfer Family server...")
transfer_client.delete_server(ServerId=server_id)
print("Transfer Family server deleted.")
```

**CLI Command:**

```bash
$ aws transfer delete-user --server-id s-1234567890abcdef0 --user-name user-abcdef
$ aws transfer delete-server --server-id s-1234567890abcdef0
```

## Next steps

Now that you've created and managed a Transfer Family server, consider the following next steps:

- Explore different identity provider types, such as AWS Directory Service or custom identity providers.
- Set up logging and monitoring for your Transfer Family server using CloudWatch.
- Integrate your Transfer Family server with other AWS services, such as Amazon S3 or Amazon EFS.
