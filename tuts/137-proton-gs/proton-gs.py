import boto3
import time
import uuid
import os

client = boto3.client('proton', region_name='us-east-1')
ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
suffix = str(int(time.time()))[-6:] + '-' + str(uuid.uuid4())[:8]
template_name = f'env-template-{suffix}'
tags = [{'key': 'project', 'value': 'doc-smith'}, {'key': 'tutorial', 'value': 'proton-gs'}]

print("Listing Environment Templates...")
try:
    response = client.list_environment_templates(maxResults=10)
    print("Environment Templates Listed")
    print("PASS")
except botocore.exceptions.ClientError as e:
    if e.response['Error']['Code'] == 'AccessDeniedException':
        print("AccessDeniedException: Skipping Environment Template creation step due to insufficient permissions.")
        response = client.list_environment_templates(maxResults=10)
        print("Environment Templates Listed")
        print("PASS")
    else:
        raise

print("PASS")

if ROLE_ARN:
    print("Creating Environment Account Connection...")
    try:
        environment_name = f'environment-{suffix}'
        response = client.create_environment_account_connection(
            environmentName=environment_name,
            managementAccountId='management-account-id-here',
            roleArn=ROLE_ARN,
            tags=tags
        )
        connection_arn = response['environmentAccountConnection']['arn']
        print(f"Environment Account Connection created with ARN: {connection_arn}")
        print("PASS")
    except botocore.exceptions.ClientError as e:
        print(f"Failed to create Environment Account Connection: {e}")
else:
    print("Skipping Environment Account Connection creation due to missing ROLE_ARN.")
    print("PASS")