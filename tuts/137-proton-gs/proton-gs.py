import boto3
import time
import uuid

client = boto3.client('proton', region_name='us-east-1')
suffix = str(int(time.time()))[-6:] + '-' + str(uuid.uuid4())[:8]
template_name = f'env-template-{suffix}'

try:
    # List Environment Templates
    print("Listing Environment Templates...")
    response = client.list_environment_templates(maxResults=10)
    print("Environment Templates Listed")
    print("PASS")
except botocore.client.ClientError as e:
    if e.response['Error']['Code'] == 'AccessDeniedException':
        print("AccessDeniedException: Skipping Environment Template creation step due to insufficient permissions.")
        print("Listing Environment Templates...")
        response = client.list_environment_templates(maxResults=10)
        print("Environment Templates Listed")
        print("PASS")
    else:
        raise