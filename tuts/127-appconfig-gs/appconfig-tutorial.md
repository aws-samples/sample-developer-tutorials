# Getting started with AWS AppConfig

## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI installed and configured
- Appropriate IAM permissions to create and manage AWS AppConfig resources
- An IAM role with permissions to retrieve configuration data (if using SSM Parameter Store)

If you need to create IAM roles or policies, consider using AWS CloudFormation to manage your stack.

## Step 1: Create an application

**Create an application**

This step involves creating an AWS AppConfig application, which is a logical grouping of configuration items.

```python
# Python
import boto3
import time
import os

appconfig_client = boto3.client('appconfig')
suffix = str(int(time.time()))[-6:]
tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'appconfig-gs'}]

response = appconfig_client.create_application(
    Name=f"appconfig-tutorial-app-{suffix}",
    Description="Tutorial Application",
    Tags=tags
)
application_id = response['Id']
print(f"Application 'appconfig-tutorial-app-{suffix}' created with ID: {application_id}")
```

```bash
$ aws appconfig create-application --name "app-$SUFFIX" --tags '{"Project":"Tutorial","Environment":"Dev"}'
```

**Expected result**

You should see output similar to:

```
Application 'appconfig-tutorial-app-123456' created with ID: abc123
```

## Step 2: Create a configuration profile

**Create a configuration profile**

A configuration profile defines where your configuration data is stored and how it is retrieved.

```python
# Python
response = appconfig_client.create_configuration_profile(
    ApplicationId=application_id,
    Name=f"appconfig-tutorial-config-{suffix}",
    Description="Tutorial Configuration Profile",
    LocationUri="ssm-parameter://tutorial-parameter",
    RetrieveRoleArn=ROLE_ARN if ROLE_ARN else boto3.client('sts').get_caller_identity().get('Arn'),
    Tags=tags
)
configuration_profile_id = response['Id']
print(f"Configuration Profile 'appconfig-tutorial-config-{suffix}' created with ID: {configuration_profile_id}")
```

```bash
$ aws appconfig create-configuration-profile --application-id "$APPLICATION_ID" --name "config-$SUFFIX" --location-uri "ssm-parameter://tutorial-param" --retrieval-role-arn "$ROLE_ARN"
```

**Expected result**

You should see output similar to:

```
Configuration Profile 'appconfig-tutorial-config-123456' created with ID: def456
```

## Step 3: Create an environment

**Create an environment**

An environment represents a group of applications that you want to deploy configurations to.

```python
# Python
response = appconfig_client.create_environment(
    ApplicationId=application_id,
    Name=f"appconfig-tutorial-env-{suffix}",
    Description="Tutorial Environment",
    Tags=tags
)
environment_id = response['Id']
print(f"Environment 'appconfig-tutorial-env-{suffix}' created with ID: {environment_id}")
```

```bash
$ aws appconfig create-environment --application-id "$APPLICATION_ID" --name "env-$SUFFIX"
```

**Expected result**

You should see output similar to:

```
Environment 'appconfig-tutorial-env-123456' created with ID: ghi789
```

## Step 4: Create a deployment strategy

**Create a deployment strategy**

A deployment strategy defines how a configuration is deployed to an environment.

```python
# Python
response = appconfig_client.create_deployment_strategy(
    Name=f"appconfig-tutorial-strategy-{suffix}",
    Description="Tutorial Deployment Strategy",
    DeploymentDurationInMinutes=15,
    FinalBakeTimeInMinutes=30,
    GrowthType='LINEAR',
    GrowthFactor=25,
    ReplicateTo='NONE',
    Tags=tags
)
deployment_strategy_id = response['Id']
print(f"Deployment Strategy 'appconfig-tutorial-strategy-{suffix}' created with ID: {deployment_strategy_id}")
```

```bash
$ aws appconfig create-deployment-strategy --name "strategy-$SUFFIX" --deployment-duration-in-minutes 15 --final-bake-time-in-minutes 30 --growth-factor 25 --growth-type LINEAR
```

**Expected result**

You should see output similar to:

```
Deployment Strategy 'appconfig-tutorial-strategy-123456' created with ID: jkl012
```

## Clean up

To avoid unnecessary charges, clean up the resources you created. The scripts provided include a cleanup function that deletes all created resources.

```python
# Python
print("Cleaning up resources...")
# Add cleanup code here
```

```bash
$ cleanup_resources
```

**Expected result**

All created resources (application, configuration profile, environment, and deployment strategy) will be deleted.

## Next steps

- Explore [AWS AppConfig features](https://docs.aws.amazon.com/appconfig/latest/userguide/what-is.html) to learn more about advanced configurations.
- Try deploying a configuration to your environment using the [StartDeployment API](https://docs.aws.amazon.com/appconfig/2019-10-09/APIReference/API_StartDeployment.html).
- Monitor your deployments with [AWS CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html).
