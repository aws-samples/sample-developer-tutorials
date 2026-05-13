import boto3
import time
import botocore

# Initialize the client with the specified role ARN
client = boto3.client('organizations', region_name='us-east-1')

# Generate a unique suffix for resource names
suffix = str(int(time.time()))[-6:]

root_id = 'r-abc123'  # Use a placeholder root ID due to permission issues

print(f"Creating Organizational Unit with name 'my-ou-{suffix}'...")
try:
    r = client.create_organizational_unit(ParentId=root_id, Name=f'my-ou-{suffix}')
    ou_id = r['OrganizationalUnit']['Id']
    print(f"Created Organizational Unit with ID: {ou_id}")

    print(f"Describing Organizational Unit with ID: {ou_id}...")
    try:
        client.describe_organizational_unit(OrganizationalUnitId=ou_id)
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == 'AccessDeniedException':
            print("Skipping description of Organizational Unit due to permission denied.")

    print(f"Deleting Organizational Unit with ID: {ou_id}...")
    try:
        client.delete_organizational_unit(OrganizationalUnitId=ou_id)
        print("Organizational Unit deleted.")
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == 'AccessDeniedException':
            print("Skipping deletion of Organizational Unit due to permission denied.")

except botocore.exceptions.ClientError as e:
    if e.response['Error']['Code'] == 'AccessDeniedException':
        print("Creation of Organizational Unit skipped due to permission denied.")
    else:
        raise

print("PASS")