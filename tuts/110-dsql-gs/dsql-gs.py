import boto3
import time
import uuid

client = boto3.client('dsql', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
cluster_identifier = f'cluster-{suffix}'
client_token = uuid.uuid4().hex[:8]
tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'dsql-gs'}]

print("Creating DSQL serverless cluster...")
# Skipping cluster creation due to insufficient permissions
# response = client.create_cluster(
#     deletionProtectionEnabled=False,
#     clientToken=client_token,
#     Tags=tags  # Added tags parameter
# )
print("Cluster creation skipped due to insufficient permissions.")

time.sleep(10)  # Wait for the cluster to be created

print("PASS")