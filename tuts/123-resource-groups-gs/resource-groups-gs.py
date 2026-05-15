import boto3
import json
import time
import uuid

suffix = str(int(time.time()))[-6:]
region_name = 'us-east-1'
group_name = f'group-{suffix}'
tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'resource-groups-gs'}]

client = boto3.client('resource-groups', region_name=region_name)

print("Creating group...")
r = client.create_group(
    Name=group_name,
    Tags={tag['Key']: tag['Value'] for tag in tags},
    ResourceQuery={
        'Type': 'TAG_FILTERS_1_0',
        'Query': json.dumps({
            "ResourceTypeFilters": ["AWS::AllSupported"],
            "TagFilters": [{"Key": "project", "Values": ["doc-smith"]}]
        })
    }
)
print(f"Group created: {r['Group']['Name']}")

print("Verifying group creation...")
group = client.get_group(GroupName=group_name)
print(f"Group verified: {group['Group']['Name']}")

print("Listing groups...")
groups = client.list_groups()
print(f"Groups listed: {len(groups['GroupIdentifiers'])} groups")

print("Deleting group...")
client.delete_group(GroupName=group_name)
print("Group deleted")

print("PASS")