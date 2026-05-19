# Getting started with AWS Resilience Hub

This tutorial guides you through the process of getting started with AWS Resilience Hub using both Python and CLI scripts.

## Prerequisites

Before you begin, ensure you have met the following requirements:

- AWS CLI installed and configured with appropriate credentials.
- Necessary IAM permissions to create and manage Resilience Hub applications and policies.
- Optionally, a CloudFormation stack if specific IAM roles are required.

## Step 1: Create an application

**Python Script**

Before running the script, ensure you have set the `TUTORIAL_ROLE_ARN` environment variable.

```python
import boto3
import json
import time
import os
import sys

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
client = boto3.client('resiliencehub')
suffix = str(int(time.time()))[-6:]
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value':'resiliencehub-gs'}]

print("Step 1: Creating an application.")
app_name = f'tutorial-app-{suffix}'
response = client.create_app(name=app_name, tags=tags)
app_arn = response['app']['appArn']
print(f"Application created with ARN: {app_arn}")
```

After running the script, you should see an output similar to:

```
Application created with ARN: arn:aws:resiliencehub:us-west-2:123456789012:app/tutorial-app-123456
```

**CLI Script**

Run the following CLI command to create an application:

```bash
$ APP_NAME="app-$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)"
$ APP_ARN=$(create-app --name $APP_NAME --assessment-schedule Disabled)
```

You should see an output similar to:

```
APP_ARN=arn:aws:resiliencehub:us-west-2:123456789012:app/app-abcdef12
```

## Step 2: Create an app version resource

**Python Script**

Continue with the Python script to create an app version resource.

```python
print("Step 2: Creating an app version resource.")
response = client.create_app_version_resource(
    appArn=app_arn,
    appComponents=[{'id': 'test-component', 'name': 'test-component', 'type': 'AWS::EC2::Instance'}],
    logicalResourceId={'identifier': 'test-resource', 'logicalStackName': 'test-stack','resourceGroupName': 'test-group', 'terraformSourceName': 'test-tf-source'},
    physicalResourceId={'identifier': 'test-physical-id', 'awsAccountId': 'test-account-id', 'awsRegion': 'us-west-2'},
    resourceType='AWS::EC2::Instance'
)
print("App version resource created.")
```

After running the script, you should see:

```
App version resource created.
```

**CLI Script**

This step is not directly translatable to CLI as the CLI script provided focuses on creating an application and policy. However, you can manually add resources to your application via the AWS Management Console.

## Step 3: Describe the application

**Python Script**

Verify the creation of the application by describing it.

```python
print("Step 3: Describing the application to verify creation.")
response = client.describe_app(appArn=app_arn)
print(f"Application description retrieved: {response['app']}")
```

After running the script, you should see an output similar to:

```
Application description retrieved: {'appArn': 'arn:aws:resiliencehub:us-west-2:123456789012:app/tutorial-app-123456',...}
```

**CLI Script**

Describe the application using the following CLI command:

```bash
$ describe-app --app-arn $APP_ARN
```

You should see an output similar to:

```
{
  "appArn": "arn:aws:resiliencehub:us-west-2:123456789012:app/app-abcdef12",
 ...
}
```

## Step 4: Clean up

**Python Script**

Clean up by deleting the application.

```python
print("Step 4: Cleaning up - Deleting the application.")
client.delete_app(appArn=app_arn)
print("Application deleted.")
```

After running the script, you should see:

```
Application deleted.
```

**CLI Script**

The cleanup function in the CLI script ensures that the application and policy are deleted upon script exit.

```bash
trap cleanup EXIT
```

## Next steps

- Explore additional Resilience Hub features such as assessment templates and resiliency policies.
- Integrate Resilience Hub with your CI/CD pipeline for automated resiliency assessments.
- Review the [AWS Resilience Hub documentation](https://docs.aws.amazon.com/resilience-hub/latest/userguide/what-is.html) for more advanced use cases and best practices.
