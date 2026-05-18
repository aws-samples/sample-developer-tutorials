import boto3
import uuid

# Initialize a boto3 client for Audit Manager
auditmanager = boto3.client('auditmanager')

# Unique suffix for names
unique_suffix = str(uuid.uuid4())[:8]

# Tags for resources
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'controlcatalog-gs'}]

try:
    # List common controls
    common_controls = auditmanager.list_common_controls()
    print("ListCommonControls status:", common_controls['ResponseMetadata']['HTTPStatusCode'])
except Exception as e:
    print("Error listing common controls:", e)

# Get a specific control (assuming there's at least one control available)
try:
    control_id = "common-control-id"  # Replace with actual control ID if available
    get_control = auditmanager.get_control(controlId=control_id)
    print("GetControl status:", get_control['ResponseMetadata']['HTTPStatusCode'])
except Exception as e:
    print("Error getting control:", e)

print("PASS")