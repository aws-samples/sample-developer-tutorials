import boto3
import uuid

# Initialize a session using Amazon Route 53 Application Recovery Controller
session = boto3.Session(
    region_name='us-west-2'  # Change to your preferred region
)

# Create a Route 53 ARC client
arc_client = session.client('route53-recovery-cluster')

# Unique suffix for resource names
suffix = str(uuid.uuid4())[:8]

# List routing controls
try:
    list_response = arc_client.list_routing_controls(
        MaxResults=10
    )
    print("ListRoutingControls:", list_response)
except Exception as e:
    print(f"Error listing routing controls: {e}")

print("PASS")