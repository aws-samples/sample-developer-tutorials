# Aws Mwaa Serverless Tutorial

## Prerequisites

- Python installed on your machine
- Boto3 library installed (`$ pip install boto3`)
- Aws credentials configured
- An s3 bucket with a workflow definition file

## Steps

**1. Import libraries**

```python
import boto3
import json
import time
import uuid
```

**2. Initialize boto3 client**

```python
client = boto3.client('mwaa', region_name='us-east-1')
```

**3. Set workflow parameters**

```python
suffix = str(int(time.time()))[-6:]
workflow_name = f'workflow-{suffix}'
definition_s3_location = {'Bucket': 'your-bucket', 'Key': 'your-workflow-definition.yaml'}
role_arn = 'arn:aws:iam::559823168634:role/doc-babu-mwaa-serverless-role'
tags = {'project': 'doc-smith', 'tutorial':'mwaa-serverless-gs'}
```

**4. Create cli token**

```python
try:
    response = client.create_cli_token(WebServerHostname='your-hostname')
    print("CLI token created")
except Exception as e:
    print(f"Failed to create CLI token: {e}")
```

**5. List environments**

```python
try:
    response = client.list_environments()
    environments = response['Environments']
    if environments:
        print(f"Environments: {json.dumps(environments, indent=2)}")
except Exception as e:
    print(f"Failed to list environments: {e}")
```

## Clean up

- Comment out the sections for listing workflow runs, task instances, and deleting the workflow
- Remove any unnecessary resources created during the tutorial

## Next steps

- Explore Aws Mwaa serverless further
- Try creating and managing workflows using the Aws management console
- Check out the [Aws Mwaa serverless documentation](https://docs.aws.amazon.com/mwaa/latest/userguide/what-is-mwaa.html) for more information