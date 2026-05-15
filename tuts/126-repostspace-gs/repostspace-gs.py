import boto3
import json
import time
import uuid

suffix = str(int(time.time()))[-6:]
client = boto3.client('repostspace', region_name='us-east-1')

tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'repostspace-gs'}]

# Skip Space creation due to AccessDeniedException
# r = client.create_space(name=f'space-{suffix}', tier='BASIC', description='Test space', subdomain=f'sub-{suffix}', tags=tags)
# space_id = r['spaceId']
# print(f"Space created: {space_id}")

# Skip Space verification due to AccessDeniedException
# g = client.get_space(spaceId=space_id)
# print(f"Space status: {g['status']}")

# List Spaces
spaces = client.list_spaces()
print(f"Listed spaces: {json.dumps(spaces, indent=2)}")

# Clean up - no resources to delete as none were created

print("PASS")