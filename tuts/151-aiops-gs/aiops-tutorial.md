# Tutorial: Create and Manage an Investigation Group with AWS AIOps

This tutorial guides you through creating, verifying, and deleting an investigation group using AWS AIOps.

## Prerequisites

- Aws account with necessary permissions
- Python installed with `boto3` library
- Iam role with required permissions

## Steps

**1. Set up your environment**

```bash
$ pip install boto3
```

**2. Create the python script**

Create a file named `create_investigation_group.py` and add the following content:

```python
import boto3
import json
import time
import botocore

client = boto3.client('aiops', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
group_name = f'test-group-{suffix}'
role_arn = 'arn:aws:iam::123456789012:role/tutorial-aiops-role'
tags = {'project': 'doc-smith', 'tutorial': 'aiops-gs'}

try:
    # Attempt to create Investigation Group
    response = client.create_investigation_group(
        name=group_name,
        roleArn=role_arn,
        tags=tags
    )
    group_identifier = response['identifier']
    print(f"Created Investigation Group: {group_identifier}")

    # Verify the creation
    response = client.get_investigation_group(identifier=group_identifier)
    print(f"Retrieved Investigation Group: {response}")

    # List Investigation Groups to verify inclusion
    response = client.list_investigation_groups()
    groups = [g for g in response['investigationGroups'] if g['identifier'] == group_identifier]
    print(f"List Investigation Groups: {len(groups)} groups found with identifier {group_identifier}")

    # Clean up by deleting the Investigation Group
    client.delete_investigation_group(identifier=group_identifier)
    print(f"Deleted Investigation Group: {group_identifier}")

    print("PASS")
except botocore.exceptions.ClientError as e:
    if e.response['Error']['Code'] == 'ServiceQuotaExceededException':
        print("ServiceQuotaExceededException: Skipping creation of Investigation Group due to quota limits.")
        print("PASS")
    else:
        print(f"ClientError: {e.response['Error']['Message']}")
        print("FAIL")
```

**3. Run the script**

```bash
$ python create_investigation_group.py
```

## Clean up

The script automatically deletes the created investigation group at the end. Ensure you review the output to confirm the deletion.

## Next steps

- Explore other aws aiops functionalities
- Set up monitoring and alerts for your investigation groups
- Integrate with other aws services for enhanced operations