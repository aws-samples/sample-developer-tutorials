# Getting started with AWS Lake Formation

This tutorial will guide you through the basics of using AWS Lake Formation to manage and secure your data lakes.

## Prerequisites

Before you begin, ensure you have the following:

- AWS Command Line Interface (CLI) installed and configured.
- Necessary IAM permissions to create and manage Lake Formation resources.
- A CloudFormation stack with required IAM roles if you need to set up roles specifically for this tutorial.

## Step 1: Set up your environment

**Guidance:** Set environment variables and ensure your AWS CLI is configured with the appropriate permissions.

```bash
$ export AWS_PROFILE=your_profile_name
$ export TUTORIAL_ROLE_ARN=your_role_arn_here
```

## Step 2: Create an LF-Tag

**Guidance:** Use the Python script to create an LF-Tag for categorizing your resources.

```python
import boto3
import time
import os

ROLE_ARN = os.getenv('TUTORIAL_ROLE_ARN')
suffix = str(int(time.time()))[-6:]
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'lakeformation-gs'}]

lakeformation = boto3.client('lakeformation')

# Create LF-Tag
print("Creating LF-Tag to categorize resources.")
tag_name = f'tutorial-tag-{suffix}'
response = lakeformation.create_lf_tag(CatalogId='123456789012', TagKey=tag_name, TagValues=['value1', 'value2'], Tags=tags)
print(f"LF-Tag created with key: {tag_name}")
```

**Expected Output:**
```
Creating LF-Tag to categorize resources.
LF-Tag created with key: tutorial-tag-123456
```

## Step 3: Create a Data Cells Filter

**Guidance:** Use the Python script to create a Data Cells Filter to control data access.

```python
import boto3
import time
import os

ROLE_ARN = os.getenv('TUTORIAL_ROLE_ARN')
suffix = str(int(time.time()))[-6:]

lakeformation = boto3.client('lakeformation')

# Create Data Cells Filter
print("Creating Data Cells Filter to control data access.")
filter_name = f'tutorial-filter-{suffix}'
response = lakeformation.create_data_cells_filter(
    TableData={
        'DatabaseName': 'example_db',
        'TableName': 'example_table',
        'Name': filter_name,
        'RowFilter': {
            'FilterExpression': "column1 = 'value1'"
        },
        'ColumnNames': ['column1', 'column2'],
        'ColumnWildcard': {'ExcludedColumnNames': ['column3']}
    }
)
print(f"Data Cells Filter created with name: {filter_name}")
```

**Expected Output:**
```
Creating Data Cells Filter to control data access.
Data Cells Filter created with name: tutorial-filter-123456
```

## Clean up

**Guidance:** Delete the resources you created to avoid unnecessary charges.

```bash
$ python cleanup_script.py
```

## Next steps

- Explore more Lake Formation features such as [Lake Formation permissions](https://docs.aws.amazon.com/lake-formation/latest/dg/permissions.html).
- Learn how to [integrate Lake Formation with AWS Glue](https://docs.aws.amazon.com/lake-formation/latest/dg/glue-integration.html).
- Discover how to [use Lake Formation with Amazon Athena](https://docs.aws.amazon.com/lake-formation/latest/dg/athena-integration.html).
