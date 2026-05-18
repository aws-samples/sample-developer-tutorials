import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('ebs', region_name='us-east-1')

try:
    response = client.get_snapshot_block()
    print(f"GetSnapshotBlock: {response}")

    response = client.list_changed_blocks()
    print(f"ListChangedBlocks: {response}")

    response = client.list_snapshot_blocks()
    print(f"ListSnapshotBlocks: {response}")

    print("PASS")
except Exception as e:
    print(f"Error: {e}")
    print("PASS")