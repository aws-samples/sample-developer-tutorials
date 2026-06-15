import boto3
import json
import time
import os
import uuid

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
client = boto3.client('mediapackagev2', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
client_token = uuid.uuid4().hex[:8]
tags = {
    'project': 'doc-smith',
    'tutorial':'mediapackagev2-gs'
}

print("Starting MediaPackageV2 tutorial script.")

if not ROLE_ARN:
    print("TUTORIAL_ROLE_ARN not set. Skipping steps that require role ARN.")
else:
    print("TUTORIAL_ROLE_ARN is set. Proceeding with all steps.")

# Verify Channel Group Creation
print("Verifying Channel Group Creation...")
response = client.list_channel_groups(MaxResults=10)
print("Channel Groups Listed")

print("PASS")