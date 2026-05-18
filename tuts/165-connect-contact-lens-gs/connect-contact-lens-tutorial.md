# Tutorial: Analyze Real-time Contact with Amazon Connect

## Prerequisites

- An aws account.
- Python installed on your machine.
- Boto3 python library installed. Use `$ pip install boto3` to install.

## Steps

**1. Initialize a session using amazon connect**

```python
import boto3
import uuid

# Initialize a session using amazon connect in the region of your choice
session = boto3.Session(region_name='us-west-2')
connect_client = session.client('connect')
```

**2. Create unique suffix for resource names**

```python
# Unique suffix for resource names
unique_suffix = str(uuid.uuid4())
```

**3. Define tags for resources**

```python
# Tags for resources
tags = [
    {'key': 'project', 'value': 'doc-smith'},
    {'key': 'tutorial', 'value': 'connect-contact-lens-gs'}
]
```

**4. Assume instance_id and contact_id are predefined**

```python
# Assume instance_id and contact_id are predefined
instance_id = '123456789012'
contact_id = '123456789012'
```

**5. List real-time contact analysis segments**

```python
try:
    # List real-time contact analysis segments
    response = connect_client.list_realtime_contact_analysis_segments(
        instanceid=instance_id,
        contactid=contact_id
    )

    # Print status
    print("status:", response['responsemetadata']['httpstatuscode'])

    # Print segments
    for segment in response['realtimecontactanalysissegments']:
        print(segment)

    print("pass")
except exception as e:
    print("an error occurred:", e)
```

## Clean up

Remove any resources you no longer need to avoid unnecessary charges.

## Next steps

Explore more amazon connect features and integrate them into your projects.