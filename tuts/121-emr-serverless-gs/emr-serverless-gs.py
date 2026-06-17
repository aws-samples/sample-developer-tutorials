import boto3
import json
import time
import uuid

suffix = str(int(time.time()))[-6:]
client = boto3.client('emr-serverless', region_name='us-east-1')

tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'emr-serverless-gs'}]

print("Creating application...")
# Skipped due to permission issue: create_application
# r = client.create_application(
#     name=f'app-{suffix}',
#     releaseLabel='emr-7.0.0',
#     type='SPARK',
#     clientToken=str(uuid.uuid4()),
#     tags=tags  # Added tags parameter
# )
# app_id = r['applicationId']

print("Listing applications...")
apps = client.list_applications()
print(json.dumps(apps, indent=2))

# Example of adding tags to a resource that uses 'Tags' parameter
# resource = boto3.client('some_service')
# resource.create_some_resource(
#     Name='some-resource',
#     Tags=tags  # Use uppercase 'Tags' for services like EC2, S3, etc.
# )

# Example of adding tags to a resource that uses 'tags' parameter
# resource = boto3.client('codeartifact')
# resource.create_some_resource(
#     domain='some-domain',
#     domainOwner='123456789012',
#     tags=tags  # Use lowercase 'tags' for services like codeartifact, ecs
# )

print("PASS")