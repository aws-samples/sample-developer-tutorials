import boto3
import json
import time
import uuid

client = boto3.client('detective', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
graph_name = f'test-graph-{suffix}'
tags = [
    {'Key': 'Name', 'Value': graph_name},
    {'Key': 'project', 'Value': 'doc-smith'},
    {'Key': 'tutorial', 'Value': 'detective-gs'}
]
client_token = uuid.uuid4().hex[:8]

print("Creating Amazon Detective behavior graph...")
response = client.create_graph(Tags=tags)
graph_arn = response['GraphArn']

print(f"Graph ARN: {graph_arn}")

print("Verifying graph creation...")
time.sleep(10)  # Wait for the graph to become active

response = client.list_graphs(MaxResults=10)
graphs = response['GraphList']

graph_exists = any(graph['Arn'] == graph_arn for graph in graphs)
if not graph_exists:
    print("Graph creation verification failed")
    exit(1)

print("Graph created and verified")

print("Deleting Amazon Detective behavior graph...")
delete_response = client.delete_graph(GraphArn=graph_arn)

print("Verifying graph deletion...")
time.sleep(10)  # Wait for the graph to be deleted

response = client.list_graphs(MaxResults=10)
graphs = response['GraphList']

graph_deleted = all(graph['Arn']!= graph_arn for graph in graphs)
if not graph_deleted:
    print("Graph deletion verification failed")
    exit(1)

print("Graph deleted and verified")
print("PASS")