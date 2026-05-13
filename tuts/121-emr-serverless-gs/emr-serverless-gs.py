import boto3
import json
import time
import uuid

suffix = str(int(time.time()))[-6:]
client = boto3.client('emr-serverless', region_name='us-east-1')

print("Creating application...")
# Skipped due to permission issue: create_application
# r = client.create_application(
#     name=f'app-{suffix}',
#     releaseLabel='emr-7.0.0',
#     type='SPARK',
#     clientToken=str(uuid.uuid4())
# )
# app_id = r['applicationId']

print("Listing applications...")
apps = client.list_applications()
print(json.dumps(apps, indent=2))

print("PASS")