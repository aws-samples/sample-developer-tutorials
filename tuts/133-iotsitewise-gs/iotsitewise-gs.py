import boto3
import json
import time
import os
import uuid

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
region_name = 'us-east-1'
client = boto3.client('iotsitewise', region_name=region_name)
suffix = str(int(time.time()))[-6:]
tags = {
    'project': 'doc-smith',
    'tutorial': 'iotsitewise-gs'
}

# Step 1: Create Asset Model
print("Step 1: Creating an Asset Model.")
asset_model_name = f"asset-model-{suffix}"
client_token = str(uuid.uuid4())

create_asset_model_response = client.create_asset_model(
    assetModelName=asset_model_name,
    assetModelType='ASSET_MODEL',
    assetModelProperties=[
        {
            'name': 'property1',
            'dataType': 'STRING',
            'type': {
                'attribute': {}
            },
            'unit': 'none'
        }
    ],
    clientToken=client_token,
    tags=tags
)
asset_model_id = create_asset_model_response['assetModelId']
print(f"Asset Model '{asset_model_name}' created with ID: {asset_model_id}.")

# Verify Asset Model
print("Verifying the Asset Model creation.")
describe_asset_model_response = client.describe_asset_model(assetModelId=asset_model_id)
print(f"Asset Model '{describe_asset_model_response['assetModelName']}' verified.")

# List Asset Models
list_asset_models_response = client.list_asset_models()
print(f"Listed Asset Models: {len(list_asset_models_response['assetModelSummaries'])}")

# Wait for Asset Model to become ACTIVE
print("Waiting for Asset Model to become ACTIVE.")
while True:
    asset_model_description = client.describe_asset_model(assetModelId=asset_model_id)
    if asset_model_description['assetModelStatus']['state'] == 'ACTIVE':
        break
    time.sleep(1)
print("Asset Model is now ACTIVE.")

# Step 2: Create Asset (if ROLE_ARN is set)
if ROLE_ARN:
    print("Step 2: Creating an Asset using the Asset Model.")
    asset_name = f"Asset-{suffix}"
    asset_response = client.create_asset(
        assetName=asset_name,
        assetModelId=asset_model_id,
        tags=tags
    )
    asset_id = asset_response['assetId']
    print(f"Asset '{asset_name}' created with ID: {asset_id}.")

    # Verify Asset
    print("Verifying the Asset creation.")
    describe_asset_response = client.describe_asset(assetId=asset_id)
    print(f"Asset '{describe_asset_response['assetName']}' verified.")

    # Step 3: Create Access Policy
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

# Clean up resources
print("Cleaning up resources.")
try:
    if ROLE_ARN and 'access_policy_id' in locals():
        client.delete_access_policy(accessPolicyId=access_policy_id)
        print(f"Access Policy '{access_policy_name}' deleted.")
    if 'asset_id' in locals():
        client.delete_asset(assetId=asset_id)
        print(f"Asset '{asset_name}' deleted.")
    client.delete_asset_model(assetModelId=asset_model_id)
    print(f"Asset Model '{asset_model_name}' deleted.")
except Exception as e:
    print(f"An error occurred while cleaning up resources: {e}")