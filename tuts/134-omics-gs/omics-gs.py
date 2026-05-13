import boto3
import json
import time
import uuid

region_name = 'us-east-1'
client = boto3.client('omics', region_name=region_name)
suffix = str(int(time.time()))[-6:]
name = f"test-sequence-store-{suffix}"
description = "Test sequence store for demonstration"
client_token = uuid.uuid4().hex[:8]

print(f"Creating sequence store with name: {name}")

response = client.create_sequence_store(
    name=name,
    description=description,
    clientToken=client_token
)

sequence_store_id = response['id']
print(f"Sequence store created with ID: {sequence_store_id}")

print("Verifying sequence store creation")
get_response = client.get_sequence_store(id=sequence_store_id)
print(f"Retrieved sequence store: {get_response['name']}")

print("Listing sequence stores")
list_response = client.list_sequence_stores(maxResults=10)
print(f"List of sequence stores: {list_response}")

print("Deleting sequence store")
client.delete_sequence_store(id=sequence_store_id)
print("Sequence store deleted")

print("PASS")