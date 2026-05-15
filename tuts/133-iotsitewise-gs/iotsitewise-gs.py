import boto3
import json
import time
import uuid

region_name = 'us-east-1'
client = boto3.client('iotsitewise', region_name=region_name)
suffix = str(int(time.time()))[-6:]
asset_model_name = f'asset-model-{suffix}'
client_token = str(uuid.uuid4())

tags = [
    {'Key': 'project', 'Value': 'doc-smith'},
    {'Key': 'tutorial', 'Value': 'iotsitewise-gs'}
]

# Create Asset Model
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

print(f"Asset Model created: {asset_model_name}")

# Describe Asset Model
describe_asset_model_response = client.describe_asset_model(
    assetModelId=asset_model_id
)
print(f"Described Asset Model: {describe_asset_model_response['assetModelName']}")

# List Asset Models
list_asset_models_response = client.list_asset_models()
print(f"Listed Asset Models: {len(list_asset_models_response['assetModelSummaries'])}")

# Wait for Asset Model to become ACTIVE
while True:
    asset_model_description = client.describe_asset_model(assetModelId=asset_model_id)
    if asset_model_description['assetModelStatus']['state'] == 'ACTIVE':
        break
    time.sleep(1)

# Delete Asset Model
delete_asset_model_response = client.delete_asset_model(
    assetModelId=asset_model_id,
    clientToken=client_token
)
print(f"Asset Model deleted: {asset_model_name}")

print("PASS")