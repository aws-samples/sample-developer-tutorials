# Launch Wizard Tutorial

## Prerequisites

- Python installed on your machine.
- AWS credentials configured with appropriate permissions.
- Boto3 python library installed (```$ pip install boto3```).

## Steps

### 1. List Existing Deployments

**Code block:**

```python
import boto3
import json
import time

suffix = str(int(time.time()))[-6:]
client = boto3.client('launch-wizard', region_name='us-east-1')

# List existing deployments
deployments = client.list_deployments()
print(f"Existing Deployments: {len(deployments.get('deployments', []))}")
```

**Expected output:**

```
Existing Deployments: [number]
```

### 2. List Events for a Deployment

**Code block:**

```python
# Check if there are any deployments to list events for
if deployments.get('deployments'):
    deployment_id = deployments['deployments'][0]['id']
    events = client.list_deployment_events(deploymentId=deployment_id)
    print(f"Events for Deployment {deployment_id}: {len(events.get('deploymentEvents', []))}")
else:
    print("No deployments available to list events for.")
```

**Expected output:**

```
Events for Deployment [id]: [number]
```
or
```
No deployments available to list events for.
```

### 3. Create a New Deployment

**Code block:**

```python
# Example of creating a deployment (uncomment and modify as needed)
# response = client.create_deployment(
#     workloadName='example-workload',
#     deploymentPatternName='example-pattern',
#     name=f'example-deployment-{suffix}',
#     specifications=json.dumps({
#         'key1': 'value1',
#         'key2': 'value2'
#     }),
#     tags=[
#         {'Key': 'project', 'Value': 'doc-smith'},
#         {'Key': 'tutorial', 'Value': 'launch-wizard-gs'}
#     ]
# )
# print(f"Created Deployment: {response['id']}")
```

**Expected output:**

```
Created Deployment: [id]
```

## Clean up

- Delete any created resources to avoid unnecessary charges.

## Next steps

- Explore more Launch Wizard features.
- Integrate with other AWS services.