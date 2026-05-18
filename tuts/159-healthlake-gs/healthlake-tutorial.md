# Amazon HealthLake Tutorial

## Prerequisites

- Python installed on your machine.
- AWS account with appropriate permissions.
- Boto3 library installed: `$ pip install boto3`.

## Steps

### Create FHIR Datastore

**Create FHIR Datastore**

```python
import boto3
import json
import time

suffix = str(int(time.time()))[-6:]
client = boto3.client('healthlake', region_name='us-east-1')

r = client.create_fhir_datastore(
    DatastoreTypeVersion='R4',
    DatastoreName=f'store-{suffix}',
    Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'healthlake-gs'}]
)
datastore_id = r['DatastoreId']
print(f"Datastore: {datastore_id}")
```

**Wait for ACTIVE status**

```python
for _ in range(20):
    d = client.describe_fhir_datastore(DatastoreId=datastore_id)
    if d['DatastoreProperties']['DatastoreStatus'] == 'ACTIVE': 
        break
    time.sleep(15)
```

### List FHIR Datastores

**List FHIR Datastores**

```python
datastores = client.list_fhir_datastores()
print("List of Datastores:", json.dumps(datastores, default=str, indent=2))
```

### Delete FHIR Datastore

**Delete FHIR Datastore**

```python
client.delete_fhir_datastore(DatastoreId=datastore_id)
```

**Wait for DELETED status**

```python
for _ in range(20):
    d = client.describe_fhir_datastore(DatastoreId=datastore_id)
    if d['DatastoreProperties']['DatastoreStatus'] == 'DELETED': 
        break
    time.sleep(15)
```

**Print PASS**

```python
print("PASS")
```

## Clean up

Ensure that you delete any resources you created to avoid unnecessary charges.

## Next steps

Explore more about Amazon HealthLake and its capabilities.