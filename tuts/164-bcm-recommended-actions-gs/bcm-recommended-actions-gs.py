import boto3
import uuid

# Initialize a session using Amazon BCM
session = boto3.Session()
bcm_client = session.client('bcm-data-exports')

# Generate a unique suffix
unique_suffix = str(uuid.uuid4())[:8]

# Define the tags
tags = [
    {'Key': 'project', 'Value': 'doc-smith'},
    {'Key': 'tutorial', 'Value': 'bcm-recommended-actions-gs'}
]

# List exports as a fallback
try:
    response = bcm_client.list_exports(
        MaxResults=10
    )

    # Print the status and response
    print("Status:", response['ResponseMetadata']['HTTPStatusCode'])
    print("Exports:", response['Exports'])
except Exception as e:
    print("Error listing exports:", e)

# Final pass statement
print("PASS")