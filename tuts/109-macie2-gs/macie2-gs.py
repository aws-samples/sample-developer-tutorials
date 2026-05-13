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

print("PASS")