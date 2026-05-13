import boto3
import json
import time
import uuid

client = boto3.client('entityresolution', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
schema_name = f"test-schema-{suffix}"
idempotency_token = uuid.uuid4().hex[:8]

# Create Schema Mapping
print("Creating Schema Mapping...")
response = client.create_schema_mapping(
    schemaName=schema_name,
    description="Test schema for entity resolution",
    mappedInputFields=[
        {
            'fieldName': 'uniqueId',
            'type':'UNIQUE_ID'
        },
        {
            'fieldName': 'firstName',
            'type':'NAME_FIRST'
        },
        {
            'fieldName': 'lastName',
            'type':'NAME_LAST'
        },
        {
            'fieldName': 'email',
            'type':'EMAIL_ADDRESS'
        }
    ],
    tags={'environment': 'test'}
)
print("Schema Mapping Created:", response)

# Verify Schema Mapping
print("Verifying Schema Mapping...")
response = client.get_schema_mapping(schemaName=schema_name)
print("Schema Mapping Verified:", response)

# List Schema Mappings
print("Listing Schema Mappings...")
response = client.list_schema_mappings(maxResults=10)
print("Schema Mappings Listed:", response)

# Delete Schema Mapping
print("Deleting Schema Mapping...")
response = client.delete_schema_mapping(schemaName=schema_name)
print("Schema Mapping Deleted:", response)

print("PASS")