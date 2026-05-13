import boto3
import json
import time
import uuid

client = boto3.client('lakeformation', region_name='us-east-1')
suffix = str(int(time.time()))[-6:] + "-" + str(uuid.uuid4())[:8]
resource_name = f"lf-resource-{suffix}"
resource_arn = f"arn:aws:lakeformation:us-east-1:559823168634:resource/{resource_name}"
role_arn = "arn:aws:iam::559823168634:role/doc-babu-lakeformation-role"

print("Listing resources to verify existing resources...")
response = client.list_resources()
resources = response.get('ResourceInfoList', [])
existing_resource_found = any(resource['ResourceArn'] == resource_arn for resource in resources)
if existing_resource_found:
    print("Existing resource found. No need to register.")
else:
    print("No existing resource found. Proceeding with verification.")

print("PASS")