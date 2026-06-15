# Getting started with AWS Well-Architected Tool

This tutorial will guide you through the basics of using the AWS Well-Architected Tool (WAT) to evaluate your workloads against AWS Well-Architected Framework best practices.

## Prerequisites

Before you begin, ensure you have the following:

- AWS Command Line Interface (CLI) installed and configured.
- Required IAM permissions to create and manage Well-Architected resources.
- Optionally, a CloudFormation stack if you need to assume roles for the tutorial.

## Step 1: Create a Well-Architected Profile

**Guidance:** A Well-Architected Profile is a collection of questions and best practices that you can use to evaluate your workloads.

```python
# Python script to create a Well-Architected Profile
import boto3, json, time, os, sys

# Initialize boto3 client for Well-Architected
wellarchitected = boto3.client('wellarchitected')

# Generate a unique suffix for resource names
suffix = str(int(time.time()))[-6:]

# Define tags for resources
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'wellarchitected-gs'}]

# Create a Profile
print("Creating a Well-Architected Profile.")
profile_name = f"Profile-{suffix}"
profile_description = "This is a test profile for the Well-Architected tutorial."
profile_questions = [
    {
        "QuestionId": "Q1",
        "SelectedChoices": ["SC1"]
    }
]
client_request_token = str(int(time.time()))
create_profile_response = wellarchitected.create_profile(
    ProfileName=profile_name,
    ProfileDescription=profile_description,
    ProfileQuestions=profile_questions,
    ClientRequestToken=client_request_token,
    Tags=tags
)
profile_arn = create_profile_response['ProfileArn']
print(f"Profile created with ARN: {profile_arn}")
```

**Expected Output:**
```
Profile created with ARN: arn:aws:wellarchitected:us-east-1:123456789012:profile/Profile-abc123
```

## Step 2: Create a Lens Version

**Guidance:** A Lens in Well-Architected Tool is a set of questions and best practices that you can use to evaluate your workloads.

```python
# Python script to create a Well-Architected Lens Version
print("Creating a Well-Architected Lens Version.")
lens_alias = f"Lens-{suffix}"
lens_version = "1.0"
create_lens_version_response = wellarchitected.create_lens_version(
    LensAlias=lens_alias,
    LensVersion=lens_version,
    ClientRequestToken=client_request_token
)
lens_arn = create_lens_version_response['LensArn']
print(f"Lens Version created with ARN: {lens_arn}")
```

**Expected Output:**
```
Lens Version created with ARN: arn:aws:wellarchitected:us-east-1:123456789012:lens/Lens-abc123
```

## Step 3: Create a Workload

**Guidance:** A Workload in Well-Architected Tool represents the AWS resources that make up your application or system.

```python
# Python script to create a Well-Architected Workload
print("Creating a Well-Architected Workload.")
workload_name = f"Workload-{suffix}"
workload_description = "This is a test workload for the Well-Architected tutorial."
workload_environments = [
    {
        "Type": "AWS_CLOUD"
    }
]
create_workload_response = wellarchitected.create_workload(
    WorkloadName=workload_name,
    WorkloadDescription=workload_description,
    Environments=workload_environments,
    ClientRequestToken=client_request_token
)
workload_id = create_workload_response['WorkloadId']
print(f"Workload created with ID: {workload_id}")
```

**Expected Output:**
```
Workload created with ID: wk-1234567890abcdef0
```

## Step 4: Create a Milestone

**Guidance:** A Milestone in Well-Architected Tool represents a point-in-time snapshot of your workload.

```python
# Python script to create a Well-Architected Milestone
print("Creating a Well-Architected Milestone.")
milestone_name = f"Milestone-{suffix}"
create_milestone_response = wellarchitected.create_milestone(
    WorkloadId=workload_id,
    MilestoneName=milestone_name,
    ClientRequestToken=client_request_token
)
milestone_number = create_milestone_response['MilestoneNumber']
print(f"Milestone created with number: {milestone_number}")
```

**Expected Output:**
```
Milestone created with number: 1
```

## Clean up

To avoid unnecessary charges, clean up the resources you created by deleting the workload, lens, and profile.

```bash
$ aws wellarchitected delete-workload --workload-id wk-1234567890abcdef0
$ aws wellarchitected delete-lens --lens-alias Lens-abc123
$ aws wellarchitected delete-profile --profile-arn arn:aws:wellarchitected:us-east-1:123456789012:profile/Profile-abc123
```

## Next steps

- Explore the [AWS Well-Architected Tool documentation](https://docs.aws.amazon.com/wellarchitected/latest/userguide/intro.html) for more details.
- Learn how to [integrate Well-Architected Tool with other AWS services](https://docs.aws.amazon.com/wellarchitected/latest/userguide/integrate-other-aws-resources.html).
- Review the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) to understand the best practices in detail.
