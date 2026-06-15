# Getting started with AWS Proton

## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI installed and configured
- Appropriate IAM permissions to create and manage AWS Proton resources
- An existing CloudFormation stack with necessary IAM roles if required

## Step 1: Create Environment Template

**Create an environment template**

The following Python script creates an environment template in AWS Proton.

```python
import boto3
import json
import time
import os
import sys

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
suffix = str(int(time.time()))[-6:]
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'proton-gs'}]

proton_client = boto3.client('proton')

# Step 1: Create Environment Template
print("Step 1: Creating Environment Template...")
template_name = f"template-{suffix}"
response = proton_client.create_environment_template(name=template_name, description="Environment Template for Tutorial", tags=tags)
template_arn = response['environmentTemplate']['arn']
print(f"Environment Template created with ARN: {template_arn}")
```

**Expected result:**

You should see output similar to:
```
Environment Template created with ARN: arn:aws:proton:region:123456789012:template/environment/template-abc123
```

## Step 2: Create Environment

**Create an environment**

The following Python script creates an environment using the environment template.

```python
# Step 2: Create Environment
print("Step 2: Creating Environment...")
environment_name = f"environment-{suffix}"
response = proton_client.create_environment(name=environment_name, templateName=template_name, spec='{}', tags=tags)
environment_arn = response['environment']['arn']
print(f"Environment created with ARN: {environment_arn}")
```

**Expected result:**

You should see output similar to:
```
Environment created with ARN: arn:aws:proton:region:123456789012:environment/environment-abc123
```

## Step 3: Create Service

**Create a service**

The following Python script creates a service in AWS Proton.

```python
# Step 3: Create Service
print("Step 3: Creating Service...")
service_name = f"service-{suffix}"
response = proton_client.create_service(name=service_name, templateName=template_name, branchName="main", repositoryConnectionArn="arn:aws:codestar-connections:region:123456789012:connection/abc123", repositoryId="repo-id", tags=tags)
service_arn = response['service']['arn']
print(f"Service created with ARN: {service_arn}")
```

**Expected result:**

You should see output similar to:
```
Service created with ARN: arn:aws:proton:region:123456789012:service/service-abc123
```

## Step 4: Create Service Instance

**Create a service instance**

The following Python script creates a service instance.

```python
# Step 4: Create Service Instance
print("Step 4: Creating Service Instance...")
service_instance_name = f"service-instance-{suffix}"
response = proton_client.create_service_instance(name=service_instance_name, serviceName=service_name, templateMajorVersion="1", templateMinorVersion="0", tags=tags)
service_instance_arn = response['serviceInstance']['arn']
print(f"Service Instance created with ARN: {service_instance_arn}")
```

**Expected result:**

You should see output similar to:
```
Service Instance created with ARN: arn:aws:proton:region:123456789012:service-instance/service-instance-abc123
```

## Clean up

The following sections explain how to clean up the resources created in this tutorial.

**Delete service instance**

```python
# Delete Service Instance
print("Deleting Service Instance...")
proton_client.delete_service_instance(name=service_instance_name, serviceName=service_name)
print("Service Instance deleted.")
```

**Delete service**

```python
# Delete Service
print("Deleting Service...")
proton_client.delete_service(name=service_name)
print("Service deleted.")
```

**Delete environment**

```python
# Delete Environment
print("Deleting Environment...")
proton_client.delete_environment(name=environment_name)
print("Environment deleted.")
```

**Delete environment template**

```python
# Delete Environment Template
print("Deleting Environment Template...")
proton_client.delete_environment_template(name=template_name)
print("Environment Template deleted.")
```

## Next steps

- Explore [AWS Proton templates](https://docs.aws.amazon.com/proton/latest/userguide/ag-templates.html) to learn more about defining infrastructure and deployment processes.
- Check out [AWS Proton services](https://docs.aws.amazon.com/proton/latest/userguide/ag-services-settings.html) for deploying and managing applications.
- Review [AWS Proton environments](https://docs.aws.amazon.com/proton/latest/userguide/ag-environments.html) to understand how to provision infrastructure.
