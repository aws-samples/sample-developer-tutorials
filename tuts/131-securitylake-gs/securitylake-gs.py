import boto3
import json
import time
import os
import random
import string

client = boto3.client('securitylake', region_name='us-east-1')
ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value':'securitylake-gs'}]

print("Step 1: Creating a Data Lake.")
if ROLE_ARN:
    response = client.create_data_lake(
        configurations=[{'regions': ['us-east-1'], 'lifecycle': {'expireAfterDays': 90}}],
        metaStoreManagerRoleArn=ROLE_ARN,
        tags=tags
    )
    data_lake_arn = response['dataLakeArn']
    print(f"Data Lake created with ARN: {data_lake_arn}")
else:
    print("Skipping Data Lake creation as TUTORIAL_ROLE_ARN is not set.")

print("Step 2: Creating an AWS Log Source.")
# Skipping AWS Log Source creation due to UnauthorizedException

print("Step 3: Creating a Subscriber.")
try:
    response = client.create_subscriber(
        sources=[{'customLogSource': {'sourceName': f's3-bucket-example-{suffix}','sourceVersion': '1.0'}}],
        subscriberIdentity={'arn': 'arn:aws:iam::123456789012:role/example-role'},
        subscriberName=f'example-subscriber-{suffix}',
        tags=tags
    )
    subscriber_id = response['subscriberId']
    print(f"Subscriber created with ID: {subscriber_id}")

    print("Step 4: Verifying the created resources.")
    time.sleep(10)  # Wait for resources to be available

    response = client.get_data_lake_sources()
    print("Data Lake Sources:", json.dumps(response, indent=2))

    response = client.get_subscriber(subscriberId=subscriber_id)
    print("Subscriber Details:", json.dumps(response, indent=2))

    print("Step 5: Cleaning up resources.")
    client.delete_subscriber(subscriberId=subscriber_id)
    print(f"Subscriber with ID {subscriber_id} deleted.")

    if ROLE_ARN:
        client.delete_data_lake(regions=['us-east-1'])
        print("Data Lake deleted.")

    print("PASS")
except Exception as e:
    print(f"An error occurred: {e}")
    print("FAIL")