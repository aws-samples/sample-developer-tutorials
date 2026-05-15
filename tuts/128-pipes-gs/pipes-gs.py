import boto3
import json
import time

sqs_client = boto3.client('sqs', region_name='us-east-1')
logs_client = boto3.client('logs', region_name='us-east-1')

suffix = str(int(time.time()))[-6:]
sqs_queue_name = f'test-queue-{suffix}'
log_group_name = f'/aws/pipes/test-log-group-{suffix}'

tags = [
    {'Key': 'project', 'Value': 'doc-smith'},
    {'Key': 'tutorial', 'Value': 'pipes-gs'}
]

# Create SQS Queue
sqs_response = sqs_client.create_queue(QueueName=sqs_queue_name)
sqs_queue_url = sqs_response['QueueUrl']

# Tagging SQS Queue
sqs_client.tag_queue(
    QueueUrl=sqs_queue_url,
    Tags=tags
)

# Create CloudWatch Log Group
logs_client.create_log_group(logGroupName=log_group_name)

# Tagging CloudWatch Log Group
logs_client.tag_log_group(
    logGroupName=log_group_name,
    tags={'project': 'doc-smith', 'tutorial': 'pipes-gs'}
)

print("Resources created")

# Clean up
logs_client.delete_log_group(logGroupName=log_group_name)
sqs_client.delete_queue(QueueUrl=sqs_queue_url)

print("Resources deleted")
print("PASS")