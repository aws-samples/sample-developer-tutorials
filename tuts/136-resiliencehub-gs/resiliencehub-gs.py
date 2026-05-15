import boto3
import json
import time
import uuid

client = boto3.client('resiliencehub', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
client_token = uuid.uuid4().hex[:8]
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value':'resiliencehub-gs'}]

# Create App
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
    print(f"Created App: {app_arn}")

    # Describe App
    describe_app_response = client.describe_app(
        appArn=app_arn
    )
    print(f"Described App: {describe_app_response['app']['name']}")

    # List Apps
    list_apps_response = client.list_apps()
    print(f"Listed Apps: {len(list_apps_response['appSummaries'])} apps found")

    # Delete App
    delete_app_response = client.delete_app(
        appArn=app_arn,
        clientToken=client_token,
        forceDelete=True
    )
    print(f"Deleted App: {app_arn}")
else:
    print("Failed to create app, no appArn in response")

print("PASS")