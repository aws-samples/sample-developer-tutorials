import boto3
import json
import time
import uuid

region_name = 'us-east-1'
suffix = str(int(time.time()))[-6:] + '-' + str(uuid.uuid4())[:8]
probe_name = f'probe-{suffix}'

client = boto3.client('networkmonitor', region_name=region_name)

tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'networkmonitor-gs'}]

print("Listing monitors...")
try:
    monitors = client.list_monitors()
    print(f"Monitors: {json.dumps(monitors, indent=2)}")
    print("PASS")
except botocore.exceptions.ClientError as e:
    if "UnrecognizedClientException" in str(e):
        print("Skipping due to invalid security token.")
    else:
        raise

# Example of how to add tagging to resource creation
try:
    response = client.create_monitor(
        monitorName=probe_name,
        # other required parameters here
        Tags=tags  # Apply tags here
    )
    print(f"Created monitor: {json.dumps(response, indent=2)}")
except botocore.exceptions.ClientError as e:
    print(f"Failed to create monitor: {e}")

# Example for services using lowercase 'tags' param (e.g., codeartifact, ecs)
# Uncomment and modify the following lines as needed for actual resource creation with lowercase 'tags'

# codeartifact_client = boto3.client('codeartifact', region_name=region_name)
# ecs_client = boto3.client('ecs', region_name=region_name)

# try:
#     codeartifact_response = codeartifact_client.create_repository(
#         domain='example-domain',
#         repository='example-repo',
#         tags=tags  # Apply tags here for codeartifact
#     )
#     print(f"Created CodeArtifact repository: {json.dumps(codeartifact_response, indent=2)}")
# except botocore.exceptions.ClientError as e:
#     print(f"Failed to create CodeArtifact repository: {e}")

# try:
#     ecs_response = ecs_client.create_cluster(
#         clusterName='example-cluster',
#         tags=tags  # Apply tags here for ECS
#     )
#     print(f"Created ECS cluster: {json.dumps(ecs_response, indent=2)}")
# except botocore.exceptions.ClientError as e:
#     print(f"Failed to create ECS cluster: {e}")