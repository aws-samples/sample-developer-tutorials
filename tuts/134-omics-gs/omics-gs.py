import boto3
import json
import time
import os
import uuid

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
region_name = 'us-east-1'
client = boto3.client('omics', region_name=region_name)
suffix = str(int(time.time()))[-6:]
tags = {'project': 'doc-smith', 'tutorial': 'omics-gs'}

# Step 1: Create Sequence Store
print("Step 1: Creating Sequence Store...")
name = f"seq-store-{suffix}"
description = "Test sequence store for demonstration"
client_token = uuid.uuid4().hex[:8]

response = client.create_sequence_store(
    name=name,
    description=description,
    clientToken=client_token,
    tags=tags
)

sequence_store_id = response['id']
print(f"Sequence store created with ID: {sequence_store_id}")

# Verify Sequence Store Creation
print("Verifying sequence store creation...")
get_response = client.get_sequence_store(id=sequence_store_id)
print(f"Retrieved sequence store: {get_response['name']}")

# List Sequence Stores
print("Listing sequence stores...")
list_response = client.list_sequence_stores(maxResults=10)
print(f"List of sequence stores: {list_response}")

# Clean up
print("Cleaning up resources...")

# Delete Sequence Store
print("Deleting Sequence Store...")
client.delete_sequence_store(id=sequence_store_id)
print("Sequence store deleted")

print("PASS")