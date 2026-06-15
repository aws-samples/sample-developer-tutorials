import boto3
import json
import time
import os
import uuid

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
client = boto3.client('resiliencehub', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
client_token = uuid.uuid4().hex[:8]
tags = {'project': 'doc-smith', 'tutorial':'resiliencehub-gs'}

print("Step 1: Creating an application.")
app_name = f"test-app-{suffix}"
create_app_response = client.create_app(
    name=app_name,
    description="Test Resilience Hub Application",
    assessmentSchedule="Disabled",
    permissionModel={
        'type': 'LegacyIAMUser'
    },
    clientToken=client_token,
    tags=tags
)
if 'appArn' in create_app_response:
    app_arn = create_app_response['appArn']
    print(f"Application created with ARN: {app_arn}")

    print("Step 2: Describing the application to verify creation.")
    describe_app_response = client.describe_app(
        appArn=app_arn
    )
    print(f"Application description retrieved: {describe_app_response['app']['name']}")

    print("Step 3: Listing all applications to verify creation.")
    list_apps_response = client.list_apps()
    print(f"Listed Apps: {len(list_apps_response['appSummaries'])} apps found")

    print("Step 4: Cleaning up - Deleting the application.")
    delete_app_response = client.delete_app(
        appArn=app_arn,
        clientToken=client_token,
        forceDelete=True
    )
    print("Application deleted.")
else:
    print("Failed to create app, no appArn in response")

print("PASS")