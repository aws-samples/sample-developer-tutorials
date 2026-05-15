import boto3
import json
import time
import uuid

client = boto3.client('schemas', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
registry_name = f'test-registry-{suffix}'
schema_name = f'test-schema-{suffix}'
content = json.dumps({'type': 'object', 'properties': {'id': {'type': 'integer'}}})
schema_type = 'JSONSchemaDraft4'

tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value':'schemas-gs'}]

print("Creating Registry...")
response = client.create_registry(
    RegistryName=registry_name,
    Description='Test Registry',
    Tags=tags
)
print("Registry Created")

time.sleep(2)

print("Describing Registry...")
response = client.describe_registry(RegistryName=registry_name)
print("Registry Described")

print("Creating Schema...")
response = client.create_schema(
    RegistryName=registry_name,
    SchemaName=schema_name,
    Content=content,
    Description='Test Schema',
    Type=schema_type,
    Tags=tags
)
print("Schema Created")

time.sleep(2)

print("Describing Schema...")
response = client.describe_schema(
    RegistryName=registry_name,
    SchemaName=schema_name
)
print("Schema Described")

print("Listing Schemas...")
response = client.list_schemas(RegistryName=registry_name)
print("Schemas Listed")

print("Deleting Schema...")
client.delete_schema(
    RegistryName=registry_name,
    SchemaName=schema_name
)
print("Schema Deleted")

time.sleep(2)

print("Deleting Registry...")
client.delete_registry(RegistryName=registry_name)
print("Registry Deleted")

print("PASS")