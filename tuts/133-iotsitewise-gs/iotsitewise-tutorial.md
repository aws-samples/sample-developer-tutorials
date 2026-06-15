# Getting started with AWS IoT SiteWise

## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI installed and configured
- Appropriate IAM permissions to create and manage AWS IoT SiteWise resources
- An IAM role ARN if you plan to create an access policy (optional)

## Step 1: Create an Asset Model

**Guidance:** In this step, you will create an asset model that defines the structure of your industrial assets.

```python
import boto3
import json
import time
import os
import sys

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
client = boto3.client('iotsitewise')
suffix = str(int(time.time()))[-6:]
tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'iotsitewise-gs'}]

# Step 1: Create Asset Model
print("Step 1: Creating an Asset Model.")
asset_model_name = f"AssetModel-{suffix}"
asset_model_response = client.create_asset_model(
    assetModelName=asset_model_name,
    assetModelProperties=[{
        'name': 'Temperature',
        'dataType': 'DOUBLE',
        'unit': 'Celsius'
    }],
    tags=tags
)
asset_model_id = asset_model_response['assetModelId']
print(f"Asset Model '{asset_model_name}' created with ID: {asset_model_id}.")
```

**Expected Result:** You should see output similar to:
```
Step 1: Creating an Asset Model.
Asset Model 'AssetModel-123456' created with ID: abc123.
```

## Step 2: Create an Asset

**Guidance:** In this step, you will create an asset based on the asset model you created in the previous step.

```python
# Step 2: Create Asset
print("Step 2: Creating an Asset using the Asset Model.")
asset_name = f"Asset-{suffix}"
asset_response = client.create_asset(
    assetName=asset_name,
    assetModelId=asset_model_id,
    tags=tags
)
asset_id = asset_response['assetId']
print(f"Asset '{asset_name}' created with ID: {asset_id}.")
```

**Expected Result:** You should see output similar to:
```
Step 2: Creating an Asset using the Asset Model.
Asset 'Asset-123456' created with ID: def456.
```

## Step 3: Create an Access Policy (Optional)

**Guidance:** In this step, you will create an access policy to grant permissions to the asset. This step is optional and requires an IAM role ARN.

```python
# Step 3: Create Access Policy
if ROLE_ARN:
    print("Step 3: Creating an Access Policy.")
    access_policy_name = f"AccessPolicy-{suffix}"
    access_policy_response = client.create_access_policy(
        accessPolicyName=access_policy_name,
        accessPolicyIdentity={
            'user': {
                'id': ROLE_ARN
            }
        },
        accessPolicyResource={
            'asset': {
                'id': asset_id
            }
        },
        accessPolicyPermissions=['ADMINISTRATOR'],
        tags=tags
    )
    access_policy_id = access_policy_response['accessPolicyId']
    print(f"Access Policy '{access_policy_name}' created with ID: {access_policy_id}.")
else:
    print("Skipping Access Policy creation because TUTORIAL_ROLE_ARN is not set.")
```

**Expected Result:** You should see output similar to:
```
Step 3: Creating an Access Policy.
Access Policy 'AccessPolicy-123456' created with ID: ghi789.
```

## Clean up

**Guidance:** To avoid unnecessary charges, clean up the resources you created.

```python
# Clean up
print("Cleaning up resources.")
if ROLE_ARN and 'access_policy_id' in locals():
    print(f"Deleting Access Policy '{access_policy_id}'.")
    client.delete_access_policy(accessPolicyId=access_policy_id)
    print(f"Access Policy '{access_policy_id}' deleted.")

print(f"Deleting Asset '{asset_id}'.")
client.delete_asset(assetId=asset_id)
print(f"Asset '{asset_id}' deleted.")

print(f"Deleting Asset Model '{asset_model_id}'.")
client.delete_asset_model(assetModelId=asset_model_id)
print(f"Asset Model '{asset_model_id}' deleted.")
```

**Expected Result:** You should see output similar to:
```
Cleaning up resources.
Deleting Access Policy 'ghi789'.
Access Policy 'ghi789' deleted.
Deleting Asset 'def456'.
Asset 'def456' deleted.
Deleting Asset Model 'abc123'.
Asset Model 'abc123' deleted.
```

## Next steps

- Explore [AWS IoT SiteWise Metrics](https://docs.aws.amazon.com/iot-sitewise/latest/userguide/metrics.html) to calculate aggregate values.
- Learn about [AWS IoT SiteWise Edge](https://docs.aws.amazon.com/iot-sitewise/latest/userguide/sw-edge.html) for local data processing.
- Check out [AWS IoT SiteWise Monitor](https://docs.aws.amazon.com/iot-sitewise/latest/userguide/monitor-getting-started.html) for web applications to visualize your data.
