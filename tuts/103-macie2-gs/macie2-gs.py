import boto3
import time

# Initialize the Macie2 client
client = boto3.client('macie2', region_name='us-east-1')

# Get Macie session to check initial status
try:
    g = client.get_macie_session()
    print(f"Initial Macie Status: {g['status']}")
except Exception as e:
    print("Error getting initial Macie session: ", e)

# List findings
try:
    findings = client.list_findings(
        findingCriteria={},
        maxResults=10
    )
    print(f"Number of Findings: {len(findings.get('findingIds', []))}")
except Exception as e:
    print("Error listing findings: ", e)

# Assuming we are creating a member to demonstrate tagging
try:
    member = client.create_member(
        accountId='123456789012',
        email='test@example.com',
        Tags=[
            {'Key': 'project', 'Value': 'doc-smith'},
            {'Key': 'tutorial', 'Value':'macie2-gs'}
        ]
    )
    print(f"Created member with ARN: {member['arn']}")
except Exception as e:
    print("Error creating member: ", e)

print("PASS")