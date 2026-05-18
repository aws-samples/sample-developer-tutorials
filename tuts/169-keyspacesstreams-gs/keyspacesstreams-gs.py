import boto3
import uuid
import time

# Initialize a boto3 client for Kinesis
kinesis_client = boto3.client('kinesis')

# Generate a unique suffix for stream names
unique_suffix = str(uuid.uuid4())

# Create a stream with a unique name
stream_name = f'example-stream-{unique_suffix}'
response = kinesis_client.create_stream(
   StreamName=stream_name,
   ShardCount=1
)
print("CreateStream status:", response['ResponseMetadata']['HTTPStatusCode'])

# List all streams to verify the creation
response = kinesis_client.list_streams()
print("ListStreams status:", response['ResponseMetadata']['HTTPStatusCode'])

# Describe the stream to get its details
time.sleep(10)  # Wait for the stream to become active
response = kinesis_client.describe_stream(StreamName=stream_name)
print("DescribeStream status:", response['ResponseMetadata']['HTTPStatusCode'])

if response['StreamDescription']['Shards']:
    # Get a shard iterator for the stream
    shard_id = response['StreamDescription']['Shards'][0]['ShardId']
    response = kinesis_client.get_shard_iterator(
       StreamName=stream_name,
       ShardId=shard_id,
       ShardIteratorType='TRIM_HORIZON'
    )
    print("GetShardIterator status:", response['ResponseMetadata']['HTTPStatusCode'])

    # Get records from the stream
    shard_iterator = response['ShardIterator']
    response = kinesis_client.get_records(ShardIterator=shard_iterator)
    print("GetRecords status:", response['ResponseMetadata']['HTTPStatusCode'])
else:
    print("No shards available in the stream.")

# Clean up by deleting the stream
response = kinesis_client.delete_stream(StreamName=stream_name)
print("DeleteStream status:", response['ResponseMetadata']['HTTPStatusCode'])

print("PASS")