import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('dynamodbstreams', region_name='us-east-1')

try:
    print("Listing streams:")
    response = client.list_streams()
    print(response)

    if response['Streams']:
        stream_arn = response['Streams'][0]['StreamArn']
        print("Describing stream:", stream_arn)
        response = client.describe_stream(StreamArn=stream_arn)
        print(response)

        shard_id = response['StreamDescription']['Shards'][0]['ShardId']
        shard_iterator_type = 'TRIM_HORIZON'
        print("Getting shard iterator for shard:", shard_id)
        response = client.get_shard_iterator(
            StreamArn=stream_arn,
            ShardId=shard_id,
            ShardIteratorType=shard_iterator_type
        )
        shard_iterator = response['ShardIterator']

        print("Getting records from shard iterator:")
        response = client.get_records(ShardIterator=shard_iterator, Limit=2)
        print(response)

    print("PASS")
except Exception as e:
    print("An error occurred:", e)