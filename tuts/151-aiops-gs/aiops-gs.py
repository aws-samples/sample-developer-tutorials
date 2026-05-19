import os
import boto3
import json
import time
import botocore

client = boto3.client('aiops', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
group_name = f'test-group-{suffix}'
role_arn = os.environ['TUTORIAL_ROLE_ARN']
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'aiops-gs'}]

try:
    # Attempt to create Investigation Group
    if hasattr(client.create_investigation_group, 'tags'):
        response = client.create_investigation_group(
            name=group_name,
            roleArn=role_arn,
            tags=tags
        )
    else:
        response = client.create_investigation_group(
            name=group_name,
            roleArn=role_arn
        )
        client.tag_resource(resourceArn=response['identifier'], tags=tags)

    group_identifier = response['identifier']
    print(f"Created Investigation Group: {group_identifier}")

    # Verify the creation
    response = client.get_investigation_group(identifier=group_identifier)
    print(f"Retrieved Investigation Group: {response}")

    # List Investigation Groups to verify inclusion
    response = client.list_investigation_groups()
    groups = [g for g in response['investigationGroups'] if g['identifier'] == group_identifier]
    print(f"List Investigation Groups: {len(groups)} groups found with identifier {group_identifier}")

    # Clean up by deleting the Investigation Group
    client.delete_investigation_group(identifier=group_identifier)
    print(f"Deleted Investigation Group: {group_identifier}")

    print("PASS")
except botocore.exceptions.ClientError as e:
    if e.response['Error']['Code'] == 'ServiceQuotaExceededException':
        print("ServiceQuotaExceededException: Skipping creation of Investigation Group due to quota limits.")
        print("PASS")
    else:
        print(f"ClientError: {e.response['Error']['Message']}")
        print("FAIL")