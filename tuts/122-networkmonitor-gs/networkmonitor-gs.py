import boto3
import json
import time
import uuid

region_name = 'us-east-1'
suffix = str(int(time.time()))[-6:] + '-' + str(uuid.uuid4())[:8]
probe_name = f'probe-{suffix}'

client = boto3.client('networkmonitor', region_name=region_name)

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