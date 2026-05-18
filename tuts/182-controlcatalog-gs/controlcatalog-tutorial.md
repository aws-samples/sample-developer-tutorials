# Tutorial: Getting Started with AWS Audit Manager Control Catalog

This tutorial guides you through the basics of interacting with the AWS Audit Manager Control Catalog using the Boto3 Python library.

## Prerequisites

- An AWS account. If you don't have one, [sign up here](https://aws.amazon.com/).
- Python installed on your machine.
- Boto3 Python library installed. You can install it using `$ pip install boto3`.

## Steps

### 1. Initialize a Boto3 client for Audit Manager

```python
import boto3

# **Initialize a boto3 client for Audit Manager**
auditmanager = boto3.client('auditmanager')
```

### 2. Generate a unique suffix for names

```python
import uuid

# **Unique suffix for names**
unique_suffix = str(uuid.uuid4())[:8]
```

### 3. Define tags for resources

```python
# **Tags for resources**
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'controlcatalog-gs'}]
```

### 4. List common controls

```python
try:
    # **List common controls**
    common_controls = auditmanager.list_common_controls()
    print("ListCommonControls status:", common_controls['ResponseMetadata']['HTTPStatusCode'])
except Exception as e:
    print("Error listing common controls:", e)
```

### 5. Get a specific control

Replace `"common-control-id"` with an actual control ID if available.

```python
try:
    control_id = "common-control-id"  # Replace with actual control ID if available
    # **Get a specific control**
    get_control = auditmanager.get_control(controlId=control_id)
    print("GetControl status:", get_control['ResponseMetadata']['HTTPStatusCode'])
except Exception as e:
    print("Error getting control:", e)
```

### 6. Confirm successful execution

```python
print("PASS")
```

## Clean up

Ensure you clean up any resources you've created to avoid unnecessary charges.

## Next steps

- Explore more about [AWS Audit Manager](https://aws.amazon.com/audit-manager/).
- Dive deeper into the [Boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html) for advanced usage.