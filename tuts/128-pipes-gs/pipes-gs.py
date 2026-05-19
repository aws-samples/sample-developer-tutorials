import boto3
import json
import time
import os

sqs_client = boto3.client('sqs', region_name='us-east-1')
logs_client = boto3.client('logs', region_name='us-east-1')

TUTORIAL_ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
suffix = str(int(time.time()))[-6:]
tags = {
    'project': 'doc-smith',
    'tutorial': 'pipes-gs'
}

# Create SQS Queue
print("Step 1: Creating SQS Queue...")
sqs_response = sqs_client.create_queue(QueueName=f'test-queue-{suffix}')
sqs_queue_url = sqs_response['QueueUrl']
print(f"SQS Queue created with URL: {sqs_queue_url}")

# Tagging SQS Queue
print("Step 2: Tagging SQS Queue...")
sqs_client.tag_queue(QueueUrl=sqs_queue_url, Tags=tags)
print("SQS Queue tagged")

# Create CloudWatch Log Group
print("Step 3: Creating CloudWatch Log Group...")
logs_client.create_log_group(logGroupName=f'/aws/pipes/test-log-group-{suffix}')
print("CloudWatch Log Group created")

# Tagging CloudWatch Log Group
print("Step 4: Tagging CloudWatch Log Group...")
logs_client.tag_log_group(logGroupName=f'/aws/pipes/test-log-group-{suffix}', tags=tags)
print("CloudWatch Log Group tagged")

# Clean up
print("Step 5: Cleaning up resources...")
logs_client.delete_log_group(logGroupName=f'/aws/pipes/test-log-group-{suffix}')
sqs_client.delete_queue(QueueUrl=sqs_queue_url)
print("Resources deleted")

print("PASS")